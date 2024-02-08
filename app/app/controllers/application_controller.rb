class ApplicationController < ActionController::API
  include Authenticatable

  private

  def authenticate_user
    render_unauthorized unless authenticated_user
  end

  def check_org_membership
    @org = authenticated_user.org
    unless @org
      render_error :not_found, ['You must join an Org first']
    end
  end

  def pagination_dict(collection)
    {
      current_page: collection.current_page,
      next_page: collection.next_page,
    }
  end

  def render_unauthorized
    error_message = "You aren't authorized to do that."
    render_error :unauthorized, [error_message]
  end

  def render_error(status, error_messages)
    render json: { error_messages: }, status:
  end

  rescue_from ActionController::ParameterMissing do |e|
    render_error :unprocessable_entity, [e.message]
  end
end
