class V1::OrgsController < ApplicationController
  PERMITTED_PARAMS = [
    :email,
    EncryptedMessage.permitted_params(:name),
    EncryptedMessage.permitted_params(:member_definition),
  ]

  before_action :check_user_org_is_in_good_standing_but_maybe_not_verified,
    only: [:verify]
  before_action :check_can_edit_org, only: [:update_my_org]

  skip_before_action :check_user_org_is_in_good_standing,
    only: [:create, :verify]

  def create
    new_org = authenticated_user.build_org(create_or_update_params)
    if new_org.save && authenticated_user.save
      render json: { id: new_org.id }, status: :created
    else
      render_error :unprocessable_entity, new_org.errors.full_messages
    end
  end

  def my_org
    render json: {
      email: (@org.email if authenticated_user.can? :edit_org),
      graph: @org.graph,
      id: @org.id,
      encrypted_name: @org.encrypted_name,
      encrypted_member_definition: @org.encrypted_member_definition,
    }.compact
  end

  def update_my_org
    if @org.update(create_or_update_params)
      head :ok
    else
      render_error :unprocessable_entity, @org.errors.full_messages
    end
  end

  def verify
    if @org.verify(params[:code])
      head :ok
    else
      render_error :forbidden, ['Invalid verification code']
    end
  end

  private

  def create_or_update_params
    params.require(:org).permit(PERMITTED_PARAMS)
  end
end
