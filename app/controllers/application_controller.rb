class ApplicationController < ActionController::API
  include Authenticatable

  private

  def authenticate_user
    render_unauthorized unless authenticated_user
  end

  def render_unauthorized
    error_message = "You aren't authorized to do that."
    render_error :unauthorized, [error_message]
  end

  def render_error(status, error_messages)
    render json: {
      error_messages: error_messages
    }, status: status
  end

  rescue_from ActionController::ParameterMissing do |e|
    render_error :unprocessable_entity, [e.message]
  end
end
