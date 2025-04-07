class V1::UsersController < ApplicationController
  PERMITTED_PARAMS = [
    :public_key_bytes,
  ]

  before_action :check_user_org_is_in_good_standing_but_maybe_not_verified,
    only: [:show]

  skip_before_action :authenticate_user, only: :create
  skip_before_action :check_user_org_is_in_good_standing, only: [:create, :show]

  def create
    new_user = User.new(create_params)
    if new_user.save
      render json: { id: new_user.id }, status: :created
    else
      render_error :unprocessable_entity, new_user.errors.full_messages
    end
  end

  def index
    initial_users = authenticated_user.org.users.omit_blocked.omit_left_org
    @query = User::Query.new(initial_users, params)
    users = @query.relation
    render json: {
      meta: (pagination_dict(users) if @query.paginates?),
      users:,
    }.compact
  end

  def show
    user = authenticated_user.org.users.with_service_stats.find params[:id]

    allowed = User::Query::ALLOWED_ATTRIBUTES + [
      *(:blocked_at if user.blocked_at?),
      *(:left_org_at if user.left_org_at?),
    ]
    render json: user.slice(allowed)
  end

  def leave_org
    begin
      authenticated_user.leave_org
    rescue ActiveRecord::RecordInvalid => invalid
      render_error :unprocessable_entity, invalid.record.errors.full_messages
    else
      head :ok
    end
  end

  private

  def create_params
    params.require(:user).permit(PERMITTED_PARAMS)
  end
end
