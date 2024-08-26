class ApplicationController < ActionController::API
  include Authenticatable

  before_action :authenticate_user
  before_action :check_user_org_is_in_good_standing

  private

  def authenticate_user
    begin
      authenticated_user
    rescue Authenticatable::BlockedUserError
      error_message = "You can't do that because you were blocked by your Org's moderators. If you think this was a mistake, please contact your Org's moderators to request that they unblock you. You can't use the app until you're unblocked."
      render_error :forbidden, [error_message]
      rescue Authenticatable::LeftOrgError
        render_error :forbidden, ["You can't do that because you left the Org"]
    rescue Authenticatable::AuthorizationError
      render_unauthorized
    rescue
      render_unauthenticated
    end
  end

  def check_user_org_is_in_good_standing(user: nil)
    check_user_belongs_to_an_org(user:)
    return if performed?

    unless @org.verified_at?
      return render_error :forbidden, ['You must verify your account first']
    end
  end

  def check_user_belongs_to_an_org(user: nil)
    user ||= authenticated_user
    @org = user.org
    unless @org
      render_error :forbidden, ['You must be in an Org to do that']
    end
  end

  def pagination_dict(collection)
    {
      current_page: collection.current_page,
      next_page: collection.next_page,
    }
  end

  def render_error(status, error_messages)
    render json: { error_messages: }, status:
  end

  def render_not_found
    render_error :not_found, ['Not found']
  end

  # For the difference between unauthorized and forbidden, see:
  # https://stackoverflow.com/a/6937030/2421313
  def render_unauthenticated
    error_message = "Invalid auth token."
    render_error :unauthorized, [error_message]
  end

  # For the difference between unauthorized and forbidden, see:
  # https://stackoverflow.com/a/6937030/2421313
  def render_unauthorized
    error_message = "You aren't allowed to do that."
    render_error :forbidden, [error_message]
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
