class Api::V1::OrgsController < ApplicationController
  PERMITTED_PARAMS = [
    :name,
    :potential_member_definition,
    :potential_member_estimate,
  ]

  def create
    new_org = Org.new(create_params)
    if new_org.save
      render json: { id: new_org.id }, status: :created
    else
      render json: {
        error_messages: new_org.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def create_params
    params.require(:org).permit(PERMITTED_PARAMS)
  end
end
