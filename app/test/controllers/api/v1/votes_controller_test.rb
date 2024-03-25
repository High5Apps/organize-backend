require "test_helper"

class Api::V1::VotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @vote = votes(:one)
    @vote.destroy!
    @params = create_params @vote.candidate_ids

    @user = @vote.user
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)
  end

  test 'should create with valid params' do
    assert_difference 'Vote.count', 1 do
      post api_v1_ballot_votes_url(@vote),
        headers: @authorized_headers,
        params: @params
    end

    assert_response :created

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_not_empty json_response.dig(:id)
  end

  test 'should update when attempting to double create' do
    [
      [[candidates(:one).id], 1],
      [[candidates(:two).id], 0],
    ].each do |candidate_ids, difference|
      assert_difference 'Vote.count', difference do
        post api_v1_ballot_votes_url(@vote),
          headers: @authorized_headers,
          params: create_params(candidate_ids)
        vote_id = JSON.parse(response.body, symbolize_names: true)[:id]
        assert_response :created
        assert_equal candidate_ids, Vote.find(vote_id).candidate_ids
      end
    end
  end

  test 'should not create with invalid authorization' do
    assert_no_difference 'Vote.count' do
      post api_v1_ballot_votes_url(@vote),
        headers: authorized_headers(@user,
          Authenticatable::SCOPE_ALL,
          expiration: 1.second.ago),
        params: @params
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    assert_no_difference 'Vote.count' do
      post api_v1_ballot_votes_url(@vote),
        headers: @authorized_headers,
        params: { vote: {} }
    end

    assert_response :unprocessable_entity
  end

  test 'should not create if user is not in an org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    assert_no_difference 'Vote.count' do
      post api_v1_ballot_votes_url(@vote),
        headers: @authorized_headers,
        params: @params
    end

    assert_response :not_found
  end

  test 'should not create on a nonexistent ballot' do
    assert_no_difference 'Vote.count' do
      post api_v1_ballot_votes_url('bad-ballot-id'),
        headers: @authorized_headers,
        params: @params
    end

    assert_response :not_found
  end

  test 'should not create if ballot belongs to another Org' do
    ballot_in_another_org = ballots(:two)
    assert_not_equal @user.org, ballot_in_another_org.org

    assert_no_difference 'Vote.count' do
      post api_v1_ballot_votes_url(ballot_in_another_org),
        headers: @authorized_headers,
        params: @params
    end

    assert_response :not_found
  end

  private

  def create_params candidate_ids
    { vote: { candidate_ids: } }
  end
end
