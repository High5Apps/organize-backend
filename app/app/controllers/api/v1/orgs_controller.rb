class Api::V1::OrgsController < ApplicationController
  PERMITTED_PARAMS = [
    EncryptedMessage.permitted_params(:name),
    EncryptedMessage.permitted_params(:potential_member_definition),
    :potential_member_definition,
  ]

  before_action :authenticate_user, only: [:create, :my_org]

  def create
    new_org = authenticated_user.build_org(create_params)
    if new_org.save && authenticated_user.save
      render json: { id: new_org.id }, status: :created
    else
      render_error :unprocessable_entity, new_org.errors.full_messages
    end
  end

  def my_org
    org = authenticated_user.org

    unless org
      return render_error :not_found, "You don't belong to an Org"
    end

    render json: {
      graph: org.graph,
      id: org.id,
      encrypted_name: org.encrypted_name,
      encrypted_potential_member_definition: org.encrypted_potential_member_definition,
      potential_member_definition: org.potential_member_definition,
    }
  end

  private

  def create_params
    params.require(:org).permit(PERMITTED_PARAMS)
  end
end
