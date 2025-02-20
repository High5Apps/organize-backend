class V1::UnionCardsController < ApplicationController
  PERMITTED_PARAMS = [
    EncryptedMessage.permitted_params(:agreement),
    EncryptedMessage.permitted_params(:email),
    EncryptedMessage.permitted_params(:employer_name),
    EncryptedMessage.permitted_params(:name),
    EncryptedMessage.permitted_params(:phone),
    :signature_bytes,
    :signed_at,
  ]

  def create
    new_union_card = authenticated_user.build_union_card create_params
    if new_union_card.save
      render json: { id: new_union_card.id }, status: :created
    else
      render_error :unprocessable_entity, new_union_card.errors.full_messages
    end
  end

  private

  def create_params
    params.require(:union_card).permit(PERMITTED_PARAMS)
  end
end
