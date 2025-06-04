class ApplicationController < ActionController::API
  include Authenticatable
  include HttpAcceptLanguage::AutoLocale
  include SetCurrentRequestDetails

  before_action :delay_development_responses
  before_action :authenticate_user
  before_action :check_user_org_is_in_good_standing

  private

  def authenticate_user
    begin
      authenticated_user
    rescue Authenticatable::BlockedUserError
      error_message = I18n.t 'errors.messages.authenticatable.blocked_user'
      render_error :forbidden, [error_message]
    rescue Authenticatable::LeftOrgError
      error_message = I18n.t 'errors.messages.authenticatable.left_org'
      render_error :forbidden, [error_message]
    rescue Authenticatable::AuthorizationError
      render_unauthorized
    rescue
      render_unauthenticated
    end
  end

  def check_user_org_is_in_good_standing(user: nil, skip_verified: false)
    user ||= authenticated_user
    @org = user.org
    unless @org
      error_message = I18n.t 'errors.messages.not_in_org'
      return render_error :forbidden, [error_message]
    end

    if @org.behind_on_payments_at?
      error_message = I18n.t 'errors.messages.behind_on_payments'
      return render_error :forbidden, [error_message]
    end

    unless skip_verified || @org.verified_at?
      error_message = I18n.t 'errors.messages.org_not_verified'
      return render_error :forbidden, [error_message]
    end
  end

  def check_user_org_is_in_good_standing_but_maybe_not_verified
    check_user_org_is_in_good_standing skip_verified: true
  end

  def delay_development_responses
    sleep 0.5 if Rails.env.development?
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

  # For the difference between unauthorized and forbidden, see:
  # https://stackoverflow.com/a/6937030/2421313
  def render_unauthenticated
    error_message = I18n.t "errors.messages.authenticatable.unauthenticated"
    render_error :unauthorized, [error_message]
  end

  # For the difference between unauthorized and forbidden, see:
  # https://stackoverflow.com/a/6937030/2421313
  def render_unauthorized
    error_message = I18n.t "errors.messages.authenticatable.unauthorized"
    render_error :forbidden, [error_message]
  end

  rescue_from ActionController::ParameterMissing do |e|
    render_error :unprocessable_entity, [e.message]
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    error_message = I18n.t "errors.messages.custom_not_found"
    render_error :not_found, [error_message]
  end

  Permission::SCOPE_SYMBOLS.each do |scope|
    define_method("check_can_#{scope.to_s}") do
      render_unauthorized unless authenticated_user.can? scope
    end
  end
end
