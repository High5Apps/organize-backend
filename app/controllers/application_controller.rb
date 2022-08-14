class ApplicationController < ActionController::API
  rescue_from ActionController::ParameterMissing do |e|
    render json: { error_messages: [e.message] }, status: :unprocessable_entity
  end
end
