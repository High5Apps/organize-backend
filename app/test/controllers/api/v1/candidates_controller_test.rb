require "test_helper"

class Api::V1::CandidatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ballot = ballots(:one)

    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)
  end

  test 'should index with valid authorization' do
    get api_v1_ballot_candidates_url(@ballot), headers: @authorized_headers
    assert_response :ok
  end

  test 'should not index with invalid authorization' do
    get api_v1_ballot_candidates_url(@ballot),
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'should not index on a non-existent ballot' do
    get api_v1_ballot_candidates_url('bad-ballot-id'),
      headers: @authorized_headers
    assert_response :not_found
  end

  test 'should not index if ballot is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get api_v1_ballot_candidates_url(@ballot), headers: @authorized_headers
    assert_response :not_found
  end

  test 'should not index if ballot belongs to another Org' do
    ballot_in_another_org = ballots(:two)
    assert_not_equal @user.org, ballot_in_another_org.org

    get api_v1_ballot_candidates_url(ballot_in_another_org),
      headers: @authorized_headers
    assert_response :not_found
  end

  test 'index should only include candidates for the given ballot' do
    get api_v1_ballot_candidates_url(@ballot), headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    candidate_jsons = json_response.dig(:candidates)
    assert_equal @ballot.candidates.count, candidate_jsons.count
    candidate_ids = candidate_jsons.map {|c| c[:id]}
    candidates = Candidate.find(candidate_ids)
    candidates.each do |candidate|
      assert_equal @ballot, candidate.ballot
    end
  end

  test 'index should only include ALLOWED_ATTRIBUTES' do
    get api_v1_ballot_candidates_url(@ballot), headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    candidates = json_response.dig(:candidates)
    assert_not_equal 0, candidates.count

    attribute_allow_list = Api::V1::CandidatesController::ALLOWED_ATTRIBUTES
    candidates.each do |candidate|
      assert_equal attribute_allow_list.count, candidate.keys.count
      attribute_allow_list.each do |attribute|
        assert candidate.key? attribute
      end
    end
  end
end
