require "test_helper"

class Api::V1::NominationsControllerTest < ActionDispatch::IntegrationTest
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
      post(api_v1_ballot_nominations_url(@nomination.ballot),
        headers: @create_headers,
        params:)
      assert_response :created
    end

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_not_nil json_response.dig(:id)
  end

  test 'should not create with invalid authorization' do
    params = destroy_template_nomination_for_create_params
    assert_no_difference 'Nomination.count' do
      post(api_v1_ballot_nominations_url(@nomination.ballot),
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
      post(api_v1_ballot_nominations_url(@nomination.ballot),
        headers: @create_headers,
        params:)
    end

    assert_response :unprocessable_entity
  end

  test 'should not create if user is not in an org' do
    params = destroy_template_nomination_for_create_params
    @nominator.update!(org: nil)
    assert_nil @nominator.reload.org

    assert_no_difference 'Nomination.count' do
      post(api_v1_ballot_nominations_url(@nomination.ballot),
        headers: @create_headers,
        params:)
    end

    assert_response :not_found
  end

  test 'should not create on a nonexistent ballot' do
    params = destroy_template_nomination_for_create_params
    assert_no_difference 'Nomination.count' do
      post(api_v1_ballot_nominations_url('bad-ballot-id'),
        headers: @create_headers,
        params:)
    end

    assert_response :not_found
  end

  test 'should not create if ballot belongs to another Org' do
    ballot_in_another_org = ballots(:two)
    assert_not_equal @nominator.org, ballot_in_another_org.org

    params = destroy_template_nomination_for_create_params
    assert_no_difference 'Nomination.count' do
      post(api_v1_ballot_nominations_url(ballot_in_another_org),
        headers: @create_headers,
        params:)
    end

    assert_response :not_found
  end

  test 'should update with valid params' do
    params = update_params accepted: false
    assert_changes -> { @nomination.reload.accepted }, from: nil, to: false do
      patch(api_v1_nomination_url(@nomination),
        headers: @update_headers,
        params:)
      assert_response :ok
    end

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_equal 1, json_response.keys.count
    json_nomination = json_response[:nomination]
    permitted_params = Api::V1::NominationsController::PERMITTED_UPDATE_PARAMS
    assert_equal json_nomination.keys.count, 1 + permitted_params.count
    assert_not_nil json_nomination[:id]
    permitted_params.each do |param|
      assert_includes json_nomination.keys, param
    end
  end

  test 'should create Candidate as a side effect of accpeting nomination' do
    params = update_params accepted: true
    assert_difference 'Candidate.count', 1 do
      assert_changes -> { @nomination.reload.accepted }, from: nil, to: true do
        patch(api_v1_nomination_url(@nomination),
          headers: @update_headers,
          params:)
      end
    end
  end

  test 'should not update with invalid authorization' do
    params = update_params accepted: false
    assert_no_changes -> { @nomination.reload.accepted } do
      patch(api_v1_nomination_url(@nomination),
        headers: authorized_headers(@nominee,
          Authenticatable::SCOPE_ALL,
          expiration: 1.second.ago),
        params:)
      assert_response :unauthorized
    end
  end

  test 'should not update with invalid params' do
    assert_no_changes -> { @nomination.reload.accepted } do
      patch(api_v1_nomination_url(@nomination),
        headers: @update_headers,
        params: {})
      assert_response :unprocessable_entity
    end
  end

  test 'should not update unless requester is nominee' do
    params = update_params accepted: false
    assert_no_changes -> { @nomination.reload.accepted } do
      patch(api_v1_nomination_url(@nomination),
        headers: authorized_headers(@nominator, Authenticatable::SCOPE_ALL),
        params:)
      assert_response :not_found
    end
  end

  test 'should not update on a nonexistent nomination' do
    params = update_params accepted: false
    patch(api_v1_nomination_url('bad-nomination-id'),
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
