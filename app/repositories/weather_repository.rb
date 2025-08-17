# repository pattern to separate concerns and abstract retrieval of address and weather information
#
# usage:
#   repository = WeatherRepository.new(weather_service, address_service)
#   weather = repository.find_weather_by_address("123 main st, city, state")
#
# attributes:
# - weather_service: service used to fetch weather data.
# - address_service: service used to look up address information.
#
# methods:
# - find_weather_by_address(address): returns weather data for the given address.
class WeatherRepository
  def initialize(weather_service, address_service)
    @address_service = address_service
    @weather_service = weather_service
  end

  def find_weather_by_address(address)
    location = @address_service.address_lookup(address)
    @weather_service.get_weather_by_zip(location.zip)
  end
end