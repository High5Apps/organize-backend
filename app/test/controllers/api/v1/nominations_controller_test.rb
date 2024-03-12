require "test_helper"

class Api::V1::NominationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nomination = nominations(:election_one_choice_four)

    @nominator = @nomination.nominator
    setup_test_key(@nominator)
    @create_headers = authorized_headers @nominator, Authenticatable::SCOPE_ALL
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

  private

  def destroy_template_nomination_for_create_params
    # Destroy the existing nomination to prevent triggering duplicate
    # validation errors
    @nomination.destroy!
    { nomination: @nomination.as_json }
  end
end
