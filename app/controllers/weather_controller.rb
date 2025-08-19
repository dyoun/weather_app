# controller to handle weather queries by address
#
# usage:
#   GET /weather?address=your_address
#
# attributes:
# - params: expects 'address'
#
# methods:
# - show: main action, renders weather data or error if address missing
# - get_weather_by_address: fetches weather data using command
# - render_missing_parameters: renders error for missing address
# - render_success_response: renders weather data as json
class WeatherController < ApplicationController
  include ErrorHandler

  def index
    if params[:address].present?
      @weather_data = get_weather_by_address
    end
  rescue Weather::Errors::ServiceUnavailableError => e
    @error = "Weather service is currently unavailable: #{e.message}"
  rescue Weather::Errors::InvalidResponseError => e
    @error = "Unable to process weather data: #{e.message}"
  rescue Weather::Errors::ApiError => e
    @error = "Weather API error: #{e.message}"
  rescue ArgumentError => e
    @error = "Invalid request: #{e.message}"
  rescue Weather::Errors::WeatherError => e
    @error = "Weather error: #{e.message}"
  end

  def show
    if params[:address].present?
      render_weather_by_address
    else
      render_missing_parameters
    end
  rescue Weather::Errors::WeatherError => e
    render_error_response("Error: #{e}", :bad_request)
  end

  private

  def render_weather_by_address
    command = GetWeatherByAddressCommand.new(address: params[:address])
    weather_data = command.execute
    render_success_response(weather_data)
  end

  def get_weather_by_address
    command = GetWeatherByAddressCommand.new(address: params[:address])
    weather_data = command.execute
    weather_data.to_h
  end

  def render_missing_parameters
    render_error_response("Please provide an 'address' parameter", :bad_request) # rubocop:disable Style/StringLiterals
  end

  def render_success_response(weather_data)
    render json: {
      weather: weather_data.to_h,
      status: 'success',
      timestamp: Time.current.iso8601
    }
  end
end
