require 'rails_helper'

RSpec.describe GetWeatherByAddressCommand do
  let(:valid_address) { "123 Main St, Seattle, WA" }
  let(:weather_repository) { instance_double(WeatherRepository) }
  let(:weather_service) { instance_double(Weather::OpenWeatherMapService) }
  let(:address_service) { instance_double(Address::OpenStreetMapService) }
  let(:weather_data) do
    WeatherData.new(
      zip: "98101",
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

  before do
    allow(WeatherRepository).to receive(:new).and_return(weather_repository)
    allow(Weather::OpenWeatherMapService).to receive(:new).and_return(weather_service)
    allow(Address::OpenStreetMapService).to receive(:new).and_return(address_service)
  end

  describe '#execute' do
    let(:command) { described_class.new(address: valid_address) }

    context 'when command is valid' do
      before do
        allow(weather_repository).to receive(:find_weather_by_address).and_return(weather_data)
      end

      it 'initializes repository with correct services' do
        expect(WeatherRepository).to receive(:new).with(weather_service, address_service)
        command.execute
      end
    end
  end
end
