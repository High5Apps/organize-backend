class Api::V1::UsersController < ApplicationController
  ALLOWED_ATTRIBUTES = [
    :id,
    :pseudonym,
  ]
  PERMITTED_PARAMS = [
    :public_key_bytes,
  ]

  before_action :authenticate_user, only: [:index, :show]
  before_action :check_org_membership, only: [:index]

  def create
    new_user = User.new(create_params)
    if new_user.save
      render json: { id: new_user.id }, status: :created
    else
      render_error :unprocessable_entity, new_user.errors.full_messages
    end
  end

  def index
    users = User::Query.new(params, initial_users: @org.users).relation
    render json: { meta: pagination_dict(users), users: }
  end

  def show
    user = authenticated_user.org.users.find_by(id: params[:id])

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
