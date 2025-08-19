require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Weather::OpenWeatherMapService do
  let(:api_key) { 'test_api_key' }
  let(:zip_code) { '98101' }
  let(:service) { described_class.new(api_key) }
  let(:http_client) { instance_double(Faraday) }
  let(:valid_response_body) do
    {
      "location" => {
        "name"    => "Seattle",
        "region"  => "Washington",
        "country" => "United States"
      },
      "current"  => {
        "temp_f"    => 75.0,
        "temp_c"    => 23.9,
        "condition" => {
          "text" => "Partly cloudy",
          "icon" => "https://cdn.weatherapi.com/weather/64x64/day/116.png"
        },
        "humidity"  => 65.0,
        "speed"     => 5.2
      }
    }.to_json
  end

  before do
    allow(Rails.cache).to receive(:fetch).and_yield
  end

  describe '#initialize' do
    it 'sets the API key from parameter' do
      service = described_class.new('custom_key')
      expect(service.instance_variable_get(:@api_key)).to eq('custom_key')
    end

    it 'sets the HTTP client' do
      service = described_class.new(api_key, http_client)
      expect(service.instance_variable_get(:@http_client)).to eq(http_client)
    end
  end

  describe '#get_weather_by_zip' do
    let(:response) { instance_double(Faraday::Response, success?: true, body: valid_response_body) }
    let(:addresses_double) { instance_double(Addresses, valid?: true, errors: { zip: [] }) }

    before do
      allow(Addresses).to receive(:new).and_return(addresses_double)
      allow(Faraday).to receive(:get).and_return(response)
    end

    context 'with valid parameters' do
      it 'returns weather data' do
        expect(Faraday).to receive(:get).with(
          "http://api.weatherapi.com/v1/current.json",
          { q: zip_code, key: api_key, units: "english" }
        ).and_return(response)

        result = service.get_weather_by_zip(zip_code)

        expect(result).to be_a(WeatherData)
        expect(result.zip).to eq(zip_code)
        expect(result.location_name).to eq("Seattle")
        expect(result.temperature_f).to eq(75.0)
        expect(result.description).to eq("Partly cloudy")
      end

      it 'caches the result for 30 minutes' do
        expect(Rails.cache).to receive(:fetch).with("weather_data_#{zip_code}", expires_in: 30.minutes)
        service.get_weather_by_zip(zip_code)
      end
    end

    context 'validation errors' do
      it 'raises ArgumentError when API key is missing' do
        service = described_class.new(nil)
        expect { service.get_weather_by_zip(zip_code) }.to raise_error(ArgumentError, "API key is required.")
      end

      it 'raises ArgumentError when zip code is missing' do
        expect { service.get_weather_by_zip(nil) }.to raise_error(ArgumentError, "Zip code is required.")
      end

      it 'raises ArgumentError when zip code is empty' do
        expect { service.get_weather_by_zip("") }.to raise_error(ArgumentError, "Zip code is required.")
      end

      it 'raises ArgumentError when zip code is invalid' do
        allow(addresses_double).to receive(:valid?).and_return(true)
        allow(addresses_double).to receive(:errors).and_return({ zip: [ "is invalid" ] })
        expect { service.get_weather_by_zip("invalid") }.to raise_error(ArgumentError, "Zip code is invalid.")
      end
    end

    context 'HTTP errors' do
      it 'raises ServiceUnavailableError on Faraday errors' do
        allow(Faraday).to receive(:get).and_raise(Faraday::Error.new("Connection failed"))
        expect { service.get_weather_by_zip(zip_code) }.to raise_error(
                                                             Weather::Errors::ServiceUnavailableError,
                                                             "Open Weather service unavailable: Connection failed"
                                                           )
      end

      it 'raises InvalidResponseError on JSON parse errors' do
        allow(Faraday).to receive(:get).and_return(
          instance_double(Faraday::Response, success?: true, body: "invalid json")
        )
        expect { service.get_weather_by_zip(zip_code) }.to raise_error(
                                                             Weather::Errors::InvalidResponseError,
                                                             /Weather parsing error:/
                                                           )
      end
    end

		# rubocop:disable all
    context 'API response errors' do
      it 'raises ApiError when API request fails' do
        failed_response = instance_double(Faraday::Response, success?: false, body: valid_response_body)
        allow(Faraday).to receive(:get).and_return(failed_response)
        expect { service.get_weather_by_zip(zip_code) }.to raise_error(
                                                             Weather::Errors::ApiError,
                                                             "API request failed"
                                                           )
      end
    end

    context 'response parsing' do
      let(:parsed_data) do
        JSON.parse(valid_response_body)
      end

      before do
        allow(Faraday).to receive(:get).and_return(response)
      end

      it 'correctly parses all weather data fields' do
        result = service.get_weather_by_zip(zip_code)

        expect(result.zip).to eq(zip_code)
        expect(result.location_name).to eq(parsed_data.dig("location", "name"))
        expect(result.location_region).to eq(parsed_data.dig("location", "region"))
        expect(result.location_country).to eq(parsed_data.dig("location", "country"))
        expect(result.icon_url).to eq(parsed_data.dig("current", "condition", "icon"))
        expect(result.temperature_f).to eq(parsed_data.dig("current", "temp_f"))
        expect(result.temperature_c).to eq(parsed_data.dig("current", "temp_c"))
        expect(result.description).to eq(parsed_data.dig("current", "condition", "text"))
        expect(result.humidity).to eq(parsed_data.dig("current", "humidity"))
        expect(result.wind_speed).to eq(parsed_data.dig("current", "speed"))
      end
    end
  end

  describe 'private methods' do
    describe '#valid_zip?' do
      it 'returns true for valid zip codes' do
        allow(Addresses).to receive(:new).with(zip: zip_code).and_return(
          instance_double(Addresses, valid?: true, errors: { zip: [] })
        )

        result = service.send(:valid_zip?, zip_code)
        expect(result).to be true
      end

      it 'returns false for invalid zip codes' do
        allow(Addresses).to receive(:new).with(zip: zip_code).and_return(
          instance_double(Addresses, valid?: true, errors: { zip: [ "is invalid" ] })
        )

        result = service.send(:valid_zip?, zip_code)
        expect(result).to be false
      end
    end

    describe '#fetch_weather_data' do
      it 'makes HTTP request with correct parameters' do
        expect(Faraday).to receive(:get).with(
          "http://api.weatherapi.com/v1/current.json",
          { q: zip_code, key: api_key, units: "english" }
        )

        service.send(:fetch_weather_data, zip_code)
      end
    end
  end
end
