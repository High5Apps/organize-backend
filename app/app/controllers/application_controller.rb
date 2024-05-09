class ApplicationController < ActionController::API
  include Authenticatable

  private

  def authenticate_user
    render_unauthorized unless authenticated_user
  end

  def check_org_membership
    @org = Org.find authenticated_user.org_id
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

  rescue_from ActiveRecord::RecordNotFound do |e|
    render_error :not_found, ['Not found']
  end

  Permission::SCOPE_SYMBOLS.each do |scope|
    define_method("check_can_#{scope.to_s}") do
      render_unauthorized unless authenticated_user.can? scope
    end
  end
end
