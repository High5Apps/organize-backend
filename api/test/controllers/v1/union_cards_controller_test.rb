require "test_helper"

class V1::UnionCardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)

    @card = union_cards(:one)
    @params = {
      union_card: @card.attributes.as_json.with_indifferent_access
        .merge(signature_bytes: Base64.strict_encode64(@card.signature_bytes)),
    }
  end

  test 'should create with valid params' do
    params = destroy_template_union_card_for_create_params
    assert_difference 'UnionCard.count', 1 do
      post v1_union_cards_url, params:, headers: @authorized_headers
      assert_response :created
    end

    response.parsed_body => { id: String, **nil }
  end

  test 'should not create with invalid authorization' do
    params = destroy_template_union_card_for_create_params
    assert_no_difference 'UnionCard.count' do
      post v1_union_cards_url,
        params:,
        headers: authorized_headers(@user,
          Authenticatable::SCOPE_ALL,
          expiration: 1.second.ago)
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    params = destroy_template_union_card_for_create_params
    assert_no_difference 'UnionCard.count' do
      post v1_union_cards_url, headers: @authorized_headers, params: {
        union_cards: params[:union_card].except(:signature_bytes)
      }
      assert_response :unprocessable_entity
    end
  end

  test 'should show my_union_card' do
    get v1_my_union_card_url, headers: @authorized_headers
    assert_response :ok

    assert_pattern do
      response.parsed_body => {
        encrypted_agreement: { c: String, n: String, t: String },
        encrypted_email: { c: String, n: String, t: String },
        encrypted_employer_name: { c: String, n: String, t: String },
        encrypted_name: { c: String, n: String, t: String },
        encrypted_phone: { c: String, n: String, t: String },
        id: String,
        signature_bytes: String,
        signed_at: String,
        user_id: String,
        **nil
      }
    end
  end

  test 'should not show my_union_card with invalid authorization' do
    get v1_my_union_card_url,
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  private

  def destroy_template_union_card_for_create_params
    # Destroy the existing union card to prevent triggering duplicate validation
    # errors
    @card.destroy!
    {
      union_card: @card.attributes.as_json.with_indifferent_access
        .merge(signature_bytes: Base64.strict_encode64(@card.signature_bytes)),
    }
  end
end
