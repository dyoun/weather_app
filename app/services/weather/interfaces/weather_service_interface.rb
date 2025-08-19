module Weather
  module Interfaces
    class WeatherServiceInterface
      def get_weather_by_zip(zip)
        raise NotImplementedError, "get_weather_by_zip method must be implemented."
      end
    end
  end
end
