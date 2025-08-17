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
# - render_weather_by_address: fetches weather data using command
# - render_missing_parameters: renders error for missing address
# - render_success_response: renders weather data as json
class WeatherController < ApplicationController
  include ErrorHandler

  def show
    if params[:address].present?
      render_weather_by_address
    else
      render_missing_parameters
    end
  rescue StandardError => e
    render_error_response(e.message, :unprocessable_content)
  end

  private

  def render_weather_by_address
    command = GetWeatherByAddressCommand.new(address: params[:address])
    weather_data = command.execute
    render_success_response(weather_data)
  end

  def render_missing_parameters
    render_error_response("Please provide an 'address' parameter", :bad_request)
  end

  def render_success_response(weather_data)
    render json: {
      weather: weather_data.to_h,
      status: 'success',
      timestamp: Time.current.iso8601
    }
  end
end