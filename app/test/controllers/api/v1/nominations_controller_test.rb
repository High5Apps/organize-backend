require "test_helper"

class Api::V1::NominationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nomination = nominations(:election_one_choice_four)
    @nomination.destroy!
    @params = { nomination: @nomination.as_json }

    @user = @nomination.nominator
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)
  end

  test 'should create with valid params' do
    assert_difference 'Nomination.count', 1 do
      post api_v1_ballot_nominations_url(@nomination.ballot),
        headers: @authorized_headers,
        params: @params
      assert_response :created
    end

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_not_nil json_response.dig(:id)
  end

  test 'should not create with invalid authorization' do
    assert_no_difference 'Nomination.count' do
      post api_v1_ballot_nominations_url(@nomination.ballot),
        headers: authorized_headers(@user,
          Authenticatable::SCOPE_ALL,
          expiration: 1.second.ago),
        params: @params
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    assert_no_difference 'Nomination.count' do
      post api_v1_ballot_nominations_url(@nomination.ballot),
        headers: @authorized_headers,
        params: { nomination: {} }
    end

    assert_response :unprocessable_entity
  end

  test 'should not create if user is not in an org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    assert_no_difference 'Nomination.count' do
      post api_v1_ballot_nominations_url(@nomination.ballot),
        headers: @authorized_headers,
        params: @params
    end

    assert_response :not_found
  end

  test 'should not create on a nonexistent ballot' do
    assert_no_difference 'Nomination.count' do
      post api_v1_ballot_nominations_url('bad-ballot-id'),
        headers: @authorized_headers,
        params: @params
    end

    assert_response :not_found
  end

  test 'should not create if ballot belongs to another Org' do
    ballot_in_another_org = ballots(:two)
    assert_not_equal @user.org, ballot_in_another_org.org

    assert_no_difference 'Nomination.count' do
      post api_v1_ballot_nominations_url(ballot_in_another_org),
        headers: @authorized_headers,
        params: @params
    end

    assert_response :not_found
  end
end
