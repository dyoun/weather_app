require_relative "interfaces/address_service_interface"

# Address lookup using open street map API:
#   https://nominatim.org/release-docs/develop/api/Overview/
# eg:
#   addr = Address::OpenStreetMapService.new
#   result = addr.address_lookup('space needle')
#
# Methods:
# - address_lookup(address): Looks up and parses an address using OpenStreetMap.
#
# Errors:
# - Raises ArgumentError if the address is blank.
# - Raises Weather::Errors::ServiceUnavailableError for unavailable service
# - Raises Weather::Errors::InvalidResponseError for parse error
# - Raises Weather::Errors::WeatherError for lookup failures or result not found
module Address
  class OpenStreetMapService < Interfaces::AddressServiceInterface
    BASE_URL = 'https://nominatim.openstreetmap.org/search'

    def initialize(http_client = Faraday)
      @http_client = http_client
    end

    def address_lookup(address)
      validate_address(address)

      response = fetch_address(address)
      parse_response(response, address)
    rescue Faraday::Error => e
      raise Weather::Errors::ServiceUnavailableError, "Open Street Map Address service unavailable: #{e.message}"
    rescue JSON::ParserError => e
      raise Weather::Errors::InvalidResponseError, "Address parsing error: #{e.message}"
    end

    private

    def validate_address(address)
      raise ArgumentError, "Address is blank" if address.blank?
    end

    def fetch_address(address)
      @http_client.get(BASE_URL, {
        q: address,
        format: "json",
        addressdetails: 1,  # return parsed address
        limit: 1
      })
    end

    def parse_response(response, address)
      raise Weather::Errors::WeatherError, "Address service lookup failed" unless response.success?

      data = JSON.parse(response.body, symbolize_names: true)
      raise Weather::Errors::WeatherError, "Address not found: #{address}" if data.empty?

      result = data.first
      Addresses.new(
        address: "#{result[:address][:house_number]} #{result[:address][:road]}",
        city: result[:address][:city],
        state: result[:address][:state],
        zip: result[:address][:postcode],
      )
    end
  end
end