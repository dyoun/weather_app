# command pattern to decouple caller/retrievers
#   GetWeatherByAddressCommand.new(address: "space needle").execute
#
# attributes:
# - address: string. address to look up weather for
#
# methods:
# - execute: validates address and returns weather data
class GetWeatherByAddressCommand
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :address, :string

  validates :address, presence: true, length: { minimum: 2 }

  def initialize(address:)
    @address = address
    super(address: address)
  end

  def execute
    raise ArgumentError, errors.full_messages.join(", ") unless valid?  # validate address, min 2 chars

    repository.find_weather_by_address(@address)
  end

  private

  def repository
    @repository ||= WeatherRepository.new(weather_service, address_service)
  end

  def weather_service
    @weather_service ||= Weather::OpenWeatherMapService.new
  end

  def address_service
    @address_service ||= Address::OpenStreetMapService.new
  end
end
