class WeatherData
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :zip, :string
  attribute :location_name, :string
  attribute :location_region, :string
  attribute :location_country, :string
  attribute :zip, :string
  attribute :icon_url, :string
  attribute :temperature_f, :float
  attribute :temperature_c, :float
  attribute :description, :string
  attribute :humidity, :float
  attribute :wind_speed, :float
  attribute :timestamp, :datetime, default: -> { Time.current }

  validates :zip, :temperature, :description, presence: true
  validates :temperature, numericality: true
  validates :humidity, :wind_speed, :latitude, :longitude, numericality: true, allow_nil: true

  def to_h
    {
      zip: zip,
      location_name: location_name,
      location_region: location_region,
      location_country: location_country,
      icon_url: icon_url,
      temperature_f: temperature_f,
      temperature_c: temperature_c,
      description: description,
      humidity: humidity,
      wind_speed: wind_speed,
      timestamp: timestamp
    }
  end
end