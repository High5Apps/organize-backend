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

  # Convert EncryptedMessage params into just the encrypted attribute name
  PERMITTED_ATTRIBUTE_NAMES = PERMITTED_PARAMS
    .map { |v| v.is_a?(Hash) ? v.keys.first : v }
    .push(:id, :user_id)

  before_action :check_can_view_union_cards, only: [:index]

  def create
    return render_error :unprocessable_entity, [
      "User #{I18n.t 'activerecord.errors.models.union_card.attributes.user.taken'}"
    ] if authenticated_user.union_card

    new_union_card = authenticated_user.build_union_card create_params
    if new_union_card.save
      render json: { id: new_union_card.id }, status: :created
    else
      render_error :unprocessable_entity, new_union_card.errors.full_messages
    end
  end

  def destroy_my_union_card
    authenticated_user.union_card&.destroy!
    head :no_content
  end

  def index
    render json: { union_cards: }
  end

  def my_union_card
    union_card = authenticated_user.union_card
    if union_card
      render json: union_card.slice(PERMITTED_ATTRIBUTE_NAMES)
        .merge(public_key_bytes: authenticated_user.public_key_bytes)
    else
      head :no_content
    end
  end

  private

  def create_params
    params.require(:union_card).permit(PERMITTED_PARAMS)
  end

  def union_cards
    authenticated_user.org&.union_cards
      .joins(:user)
      .select(PERMITTED_ATTRIBUTE_NAMES + ['users.public_key_bytes'])
  end
end
