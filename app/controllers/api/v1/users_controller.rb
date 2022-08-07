class Api::V1::UsersController < ApplicationController
  PERMITTED_PARAMS = [
    :org_id,
    :public_key,
  ]

  def create
    binary = OpenSSL::PKey::RSA.new(create_params[:public_key]).to_der
    new_user = User.new(create_params.merge public_key: binary)
    if new_user.save
      render json: { id: new_user.id }, status: :created
    else
      render json: {
        error_messages: new_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def create_params
    params.require(:user).permit(PERMITTED_PARAMS)
  end
end
