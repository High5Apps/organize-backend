require "test_helper"

class Api::V1::VotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @vote = votes(:five)
    @vote.destroy!
    @params = create_params @vote.candidate_ids

    @user = @vote.user
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)
  end

  test 'should create with valid params' do
    assert_difference 'Vote.count', 1 do
      post api_v1_ballot_votes_url(@vote.ballot),
        headers: @authorized_headers,
        params: @params
    end

    assert_response :created
    assert_pattern { response.parsed_body => id: String, **nil }
  end

  test 'should update when attempting to double create' do
    [
      [[@vote.ballot.candidates.first.id], 1],
      [[@vote.ballot.candidates.second.id], 0],
    ].each do |candidate_ids, difference|
      assert_difference 'Vote.count', difference do
        post api_v1_ballot_votes_url(@vote.ballot),
          headers: @authorized_headers,
          params: create_params(candidate_ids)
        assert_response :created
        response.parsed_body => id: vote_id
        assert_equal candidate_ids, Vote.find(vote_id).candidate_ids
      end
    end
  end

  test 'should not create with invalid authorization' do
    assert_no_difference 'Vote.count' do
      post api_v1_ballot_votes_url(@vote.ballot),
        headers: authorized_headers(@user,
          Authenticatable::SCOPE_ALL,
          expiration: 1.second.ago),
        params: @params
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    assert_no_difference 'Vote.count' do
      post api_v1_ballot_votes_url(@vote.ballot),
        headers: @authorized_headers,
        params: { vote: {} }
    end

    assert_response :unprocessable_entity
  end

  private

  def create_params candidate_ids
    { vote: { candidate_ids: } }
  end
end
