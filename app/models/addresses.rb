# model to validate and store address information
#
# usage:
#   addresses.new(address: "123 main st", city: "seattle", state: "wa", zip: "98101").to_h
#
# attributes:
# - address: string. street address
# - city: string. city name
# - state: string. state abbreviation
# - zip: string. 5-digit zip code
#
# validations:
# - address, city, state, zip must be present
# - zip must be a 5-digit number
#
# methods:
# - to_h: returns a hash of address attributes
class Addresses
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :address, :string
  attribute :city, :string
  attribute :state, :string
  attribute :zip, :string

  validates :address, :city, :state, :zip, presence: true
  validates :zip, presence: true, numericality: true, format: { with: /\A\d{5}\z/, message: "Zip code must be a 5-digit number." }

  def to_h
    { address: address, city: city, state: state, zip: zip }
  end
end
