# model to validate and store address information
class Addresses
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :address, :string
  attribute :city, :string
  attribute :state, :string
  attribute :zip, :string

  validates :address, :city, :state, :zip, :presence => true
  validates :zip, presence: true, numericality: true, format: { with: /\A\d{5}\z/, message: "Zip code must be a 5-digit number." }

  def to_h
    { address: address, city: city, state: state, zip: zip }
  end
end