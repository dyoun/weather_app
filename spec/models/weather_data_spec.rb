require 'rails_helper'

RSpec.describe WeatherData, type: :model do
  let(:valid_attributes) do
    {
      zip: "98101",
      location_name: "Seattle",
      location_region: "Washington",
      location_country: "United States",
      temperature_f: 75.0,
      temperature_c: 23.9,
      description: "Partly cloudy",
      humidity: 65.0,
      wind_speed: 5.2,
      icon_url: "https://cdn.weatherapi.com/weather/64x64/day/116.png",
      cached: false
    }
  end

  describe '#to_h' do
    let(:weather_data) { described_class.new(valid_attributes) }

    it 'returns a hash with all weather data' do
      result = weather_data.to_h

      expect(result).to be_a(Hash)
      expect(result[:zip]).to eq("98101")
      expect(result[:location_name]).to eq("Seattle")
      expect(result[:location_region]).to eq("Washington")
      expect(result[:location_country]).to eq("United States")
      expect(result[:temperature_f]).to eq(75.0)
      expect(result[:temperature_c]).to eq(23.9)
      expect(result[:description]).to eq("Partly cloudy")
      expect(result[:humidity]).to eq(65.0)
      expect(result[:wind_speed]).to eq(5.2)
      expect(result[:icon_url]).to eq("https://cdn.weatherapi.com/weather/64x64/day/116.png")
      expect(result[:timestamp]).to eq(weather_data.timestamp)
      expect(weather_data.cached).to eq(false)
    end
  end
end
