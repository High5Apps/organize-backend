class Api::V1::UsersController < ApplicationController
  PERMITTED_PARAMS = [
    :public_key_bytes,
  ]

  before_action :authenticate_user, only: [:show]

  def create
    new_user = User.new(create_params)
    if new_user.save
      render json: { id: new_user.id }, status: :created
    else
      render_error :unprocessable_entity, new_user.errors.full_messages
    end
  end

  def show
    user = authenticated_user.org.users.find_by(id: params[:id])
    if user
      render json: {
        id: user.id,
        pseudonym: user.pseudonym,
      }, status: :ok
    else
      render_error :not_found, ["No user found with id #{params[:id]}"]
    end
  end

  private

  def create_params
    params.require(:user).permit(PERMITTED_PARAMS)
  end
end
