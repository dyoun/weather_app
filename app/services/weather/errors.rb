# module to define custom weather error classes
module Weather
  module Errors
    class WeatherError < StandardError; end
    class ServiceUnavailableError < WeatherError; end
    class InvalidResponseError < WeatherError; end
    class ApiError < WeatherError; end
    class GeocodingError < WeatherError; end
  end
end