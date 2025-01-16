require "test_helper"

class V1::NominationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nomination = nominations(:election_one_choice_four)

    @nominator = @nomination.nominator
    setup_test_key(@nominator)
    @create_headers = authorized_headers @nominator, Authenticatable::SCOPE_ALL

    @nominee = @nomination.nominee
    setup_test_key(@nomination.nominee)
    @update_headers = authorized_headers @nominee, Authenticatable::SCOPE_ALL
  end

  test 'should create with valid params' do
    params = destroy_template_nomination_for_create_params
    assert_difference 'Nomination.count', 1 do
      post(v1_ballot_nominations_url(@nomination.ballot),
        headers: @create_headers,
        params:)
      assert_response :created
    end

    assert_pattern { response.parsed_body => id: String, **nil }
  end

  test 'should not create with invalid authorization' do
    params = destroy_template_nomination_for_create_params
    assert_no_difference 'Nomination.count' do
      post(v1_ballot_nominations_url(@nomination.ballot),
        headers: authorized_headers(@nominator,
          Authenticatable::SCOPE_ALL,
          expiration: 1.second.ago),
        params:)
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    params = destroy_template_nomination_for_create_params.merge nomination: {}
    assert_no_difference 'Nomination.count' do
      post(v1_ballot_nominations_url(@nomination.ballot),
        headers: @create_headers,
        params:)
    end

    assert_response :unprocessable_entity
  end

  test 'should update with valid params' do
    params = update_params accepted: false
    assert_changes -> { @nomination.reload.accepted }, from: nil, to: false do
      patch(v1_nomination_url(@nomination),
        headers: @update_headers,
        params:)
      assert_response :ok
    end
  end

  test 'update response should only include ALLOWED_UPDATE_ATTRIBUTES' do
    params = update_params accepted: false
    patch(v1_nomination_url(@nomination), headers: @update_headers, params:)
    assert_equal V1::NominationsController::ALLOWED_UPDATE_ATTRIBUTES,
      response.parsed_body.keys.map(&:to_sym)
  end

  test 'update response nomination should only include ALLOWED_UPDATE_NOMINATION_ATTRIBUTES' do
    params = update_params accepted: false
    patch(v1_nomination_url(@nomination), headers: @update_headers, params:)
    response.parsed_body => nomination:
    assert_equal V1::NominationsController::ALLOWED_UPDATE_NOMINATION_ATTRIBUTES,
      nomination.keys.map(&:to_sym)
  end

  test 'update response nomination should be the same as the request' do
    params = update_params accepted: false
    patch(v1_nomination_url(@nomination), headers: @update_headers, params:)
    response.parsed_body => nomination: { id: }
    assert_equal @nomination.id, id
  end

  test 'update response candidate should only include id' do
    params = update_params accepted: false
    patch(v1_nomination_url(@nomination), headers: @update_headers, params:)
    assert_pattern { response.parsed_body => candidate: { id: nil, **nil } }
  end

  test 'update response candidate should be the newly created candidate' do
    params = update_params accepted: true
    patch(v1_nomination_url(@nomination), headers: @update_headers, params:)
    response.parsed_body => candidate: { id: candidate_id }
    assert_equal @nomination.reload.candidate.id, candidate_id
  end

  test 'should create Candidate as a side effect of accpeting nomination' do
    params = update_params accepted: true
    assert_difference 'Candidate.count', 1 do
      assert_changes -> { @nomination.reload.accepted }, from: nil, to: true do
        patch(v1_nomination_url(@nomination),
          headers: @update_headers,
          params:)
      end
    end
  end

  test 'should not update with invalid authorization' do
    params = update_params accepted: false
    assert_no_changes -> { @nomination.reload.accepted } do
      patch(v1_nomination_url(@nomination),
        headers: authorized_headers(@nominee,
          Authenticatable::SCOPE_ALL,
          expiration: 1.second.ago),
        params:)
      assert_response :unauthorized
    end
  end

  test 'should not update with invalid params' do
    assert_no_changes -> { @nomination.reload.accepted } do
      patch(v1_nomination_url(@nomination),
        headers: @update_headers,
        params: {})
      assert_response :unprocessable_entity
    end
  end

  test 'should not update unless requester is nominee' do
    params = update_params accepted: false
    assert_no_changes -> { @nomination.reload.accepted } do
      patch(v1_nomination_url(@nomination),
        headers: authorized_headers(@nominator, Authenticatable::SCOPE_ALL),
        params:)
      assert_response :not_found
    end
  end

  test 'should not update on a nonexistent nomination' do
    params = update_params accepted: false
    patch(v1_nomination_url('bad-nomination-id'),
      headers: @update_headers,
      params:)
    assert_response :not_found
  end

  private

  def destroy_template_nomination_for_create_params
    # Destroy the existing nomination to prevent triggering duplicate
    # validation errors
    @nomination.destroy!
    { nomination: @nomination.as_json }
  end

  def update_params accepted:
    { nomination: { accepted: } }
  end
end
