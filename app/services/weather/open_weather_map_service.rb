require_relative 'interfaces/weather_service_interface'

module Weather
  class OpenWeatherMapService < Interfaces::WeatherServiceInterface
    BASE_URL = 'http://api.weatherapi.com/v1'

    def initialize(api_key = ENV['OPEN_WEATHER_API_KEY'], http_client = Faraday)
      @api_key = api_key
      @http_client = http_client
    end

    def get_weather_by_zip(zip)
      validate(zip)
      response = fetch_weather_data(zip)
      parse_weather_response(response, zip)
    rescue Faraday::Error => e
      raise Weather::Errors::ServiceUnavailableError, "Open Weather service unavailable: #{e.message}"
    rescue JSON::ParserError => e
      raise Weather::Errors::InvalidResponseError, "Weather parsing error: #{e.message}"
    end

    private

    def validate(zip)
      raise ArgumentError, "API key is required." unless @api_key
      raise ArgumentError, "Zip code is required." unless zip.present?
      raise ArgumentError, "Zip code is invalid." unless valid_zip?(zip)
    end

    def valid_zip?(zip)
      address = Addresses.new(zip: zip)
      address.valid?
      !address.errors[:zip].present?
    end

    def fetch_weather_data(zip)
      @http_client.get(BASE_URL + "/current.json", {
        q: zip,
        key: @api_key,
        units: "english"
      })
    end

    def parse_weather_response(response, zip)
      raise Weather::Errors::ApiError, "API request failed" unless response.success?

      data = JSON.parse(response.body)

      WeatherData.new(
        zip: zip,
        location_name: data.dig("location", "name"),
        location_region: data.dig("location", "region"),
        location_country: data.dig("location", "country"),
        icon_url: data.dig("current", "condition", "icon"),
        temperature_f: data.dig("current", "temp_f"),
        temperature_c: data.dig("current", "temp_c"),
        description: data.dig("current", "condition", "text"),
        humidity: data.dig("current", "humidity"),
        wind_speed: data.dig("current", "speed"),
      )
    end
  end
end