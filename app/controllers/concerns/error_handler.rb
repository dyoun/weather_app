# module to handle errors and render consistent error responses
#
# usage:
#   include errorhandler in controllers to automatically rescue and handle errors
module ErrorHandler
  # ...
end
module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from Weather::Errors::WeatherError, with: :handle_weather_error
    rescue_from ArgumentError, with: :handle_argument_error
    rescue_from StandardError, with: :handle_standard_error
  end

  private

  def handle_weather_error(exception)
    render_error_response(exception.message, :unprocessable_entity)
  end

  def handle_argument_error(exception)
    render_error_response(exception.message, :bad_request)
  end

  def handle_standard_error(exception)
    Rails.logger.error "Unexpected error: #{exception.class} - #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")

    render_error_response("An unexpected error occurred", :internal_server_error)
  end

  def render_error_response(message, status)
    render json: {
      error: message,
      status: 'error',
      timestamp: Time.current.iso8601
    }, status: status
  end
end