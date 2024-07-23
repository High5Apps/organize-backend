class Api::V1::UsersController < ApplicationController
  ALLOWED_ATTRIBUTES = [
    :blocked,
    :connection_count,
    :id,
    :joined_at,
    :offices,
    :pseudonym,
    :recruit_count,
  ]
  PERMITTED_PARAMS = [
    :public_key_bytes,
  ]

  skip_before_action :authenticate_user, only: :create

  def create
    new_user = User.new(create_params)
    if new_user.save
      render json: { id: new_user.id }, status: :created
    else
      render_error :unprocessable_entity, new_user.errors.full_messages
    end
  end

  def index
    initial_users = authenticated_user.org&.users&.omit_blocked
    @query = User::Query.new(initial_users, params)
    users = @query.relation
    render json: {
      meta: (pagination_dict(users) if @query.paginates?),
      users:,
    }.compact
  end

  def show
    user = authenticated_user.org.users.with_service_stats
      .find_by(id: params[:id])

    unless user
      return render_error :not_found, ["No user found with id #{params[:id]}"]
    end

    render json: user.slice(ALLOWED_ATTRIBUTES)
  end

  private

  def create_params
    params.require(:user).permit(PERMITTED_PARAMS)
  end
end
