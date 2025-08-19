require 'rails_helper'

RSpec.describe WeatherRepository do
  let(:weather_service) { instance_double(Weather::OpenWeatherMapService) }
  let(:address_service) { instance_double(Address::OpenStreetMapService) }
  let(:repository) { described_class.new(weather_service, address_service) }
  let(:address) { "123 Main St, Seattle, WA" }
  let(:zip_code) { "98101" }
  let(:location) { instance_double("Location", zip: zip_code) }
  let(:weather_data) do
    WeatherData.new(
      zip: zip_code,
      location_name: "Seattle",
      location_region: "Washington",
      location_country: "United States",
      temperature_f: 75.0,
      temperature_c: 23.9,
      description: "Partly cloudy",
      humidity: 65.0,
      wind_speed: 5.2
    )
  end

  describe '#initialize' do
    it 'sets the weather service' do
      expect(repository.instance_variable_get(:@weather_service)).to eq(weather_service)
    end

    it 'sets the address service' do
      expect(repository.instance_variable_get(:@address_service)).to eq(address_service)
    end

    it 'requires both services as parameters' do
      expect { described_class.new }.to raise_error(ArgumentError)
      expect { described_class.new(weather_service) }.to raise_error(ArgumentError)
      expect { described_class.new(weather_service, address_service) }.not_to raise_error
    end
  end

  describe '#find_weather_by_address' do
    context 'with valid address and services' do
      before do
        allow(address_service).to receive(:address_lookup).with(address).and_return(location)
        allow(weather_service).to receive(:get_weather_by_zip).with(zip_code).and_return(weather_data)
      end

      it 'calls address service to lookup location' do
        expect(address_service).to receive(:address_lookup).with(address)
        repository.find_weather_by_address(address)
      end

      it 'calls weather service with zip code from location' do
        expect(weather_service).to receive(:get_weather_by_zip).with(zip_code)
        repository.find_weather_by_address(address)
      end

      it 'returns weather data from weather service' do
        result = repository.find_weather_by_address(address)
        expect(result).to eq(weather_data)
      end

      it 'passes zip code correctly between services' do
        allow(location).to receive(:zip).and_return("90210")
        expect(weather_service).to receive(:get_weather_by_zip).with("90210")
        repository.find_weather_by_address(address)
      end
    end

    context 'when address service raises an error' do
      before do
        allow(address_service).to receive(:address_lookup).and_raise(
          ArgumentError.new("Invalid address format")
        )
      end

      it 'propagates the error from address service' do
        expect { repository.find_weather_by_address(address) }.to raise_error(
                                                                    ArgumentError,
                                                                    "Invalid address format"
                                                                  )
      end
    end

    context 'when weather service raises an error' do
      before do
        allow(address_service).to receive(:address_lookup).with(address).and_return(location)
        allow(weather_service).to receive(:get_weather_by_zip).and_raise(
          Weather::Errors::ServiceUnavailableError.new("Weather API down")
        )
      end

      it 'propagates the error from weather service' do
        expect { repository.find_weather_by_address(address) }.to raise_error(
                                                                    Weather::Errors::ServiceUnavailableError,
                                                                    "Weather API down"
                                                                  )
      end
    end

    context 'when location has nil zip code' do
      let(:location_with_nil_zip) { instance_double("Location", zip: nil) }

      before do
        allow(address_service).to receive(:address_lookup).with(address).and_return(location_with_nil_zip)
      end

      it 'passes nil zip code to weather service' do
        expect(weather_service).to receive(:get_weather_by_zip).with(nil)
        allow(weather_service).to receive(:get_weather_by_zip).and_raise(ArgumentError.new("Zip code is required"))

        expect { repository.find_weather_by_address(address) }.to raise_error(ArgumentError)
      end
    end
  end
end
