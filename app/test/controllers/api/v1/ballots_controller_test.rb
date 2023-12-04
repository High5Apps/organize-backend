require "test_helper"

class Api::V1::BallotsControllerTest < ActionDispatch::IntegrationTest
  MAX_CANDIDATES = Api::V1::BallotsController::MAX_CANDIDATES_PER_CREATE

  setup do
    @ballot = ballots(:one)
    @params = {
      ballot: @ballot.as_json,
      candidates: @ballot.candidates.as_json,
    }

    @multi_choice_ballot = ballots(:multi_choice_one)
    @multi_choice_params = {
      ballot: @multi_choice_ballot.as_json,
      candidates: @multi_choice_ballot.candidates.as_json
    }

    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)
  end

  test 'should create with valid params' do
    candidate_count = @ballot.candidates.count
    assert_not_equal 0, candidate_count

    assert_difference 'Ballot.count', 1 do
      assert_difference 'Candidate.count', candidate_count do
        post api_v1_ballots_url, headers: @authorized_headers, params: @params
      end
    end

    assert_response :created

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_not_empty json_response.dig(:id)
  end

  test 'should not crate with invalid authorization' do
    assert_no_difference 'Ballot.count' do
      assert_no_difference 'Candidate.count' do
        post api_v1_ballots_url,
          headers: authorized_headers(@user,
            Authenticatable::SCOPE_ALL,
            expiration: 1.second.ago),
          params: @params
      end
    end

    assert_response :unauthorized
  end

  test 'should not create with invalid params' do
    invalid_params = @params
    invalid_params[:ballot][:category] = nil

    assert_no_difference 'Ballot.count' do
      assert_no_difference 'Candidate.count' do
        post api_v1_ballots_url,
          headers: @authorized_headers,
          params: invalid_params
      end
    end

    assert_response :unprocessable_entity
  end

  test 'should not create multiple choice with less than 2 candidates' do
    [nil, [], [@multi_choice_params[:candidates][0]]].each do |candidates|
      post api_v1_ballots_url,
        headers: @authorized_headers,
        params: @multi_choice_params.merge(candidates: candidates)
      assert_response :unprocessable_entity
    end
  end

  test 'should not create multiple choice with more candidates than MAX_CANDIDATES_PER_CREATE' do
    valid_params = @multi_choice_params
    valid_params[:candidates] =
      [@multi_choice_ballot.candidates.first.as_json] * MAX_CANDIDATES
    post api_v1_ballots_url, headers: @authorized_headers, params: valid_params
    assert_response :created

    invalid_params = @multi_choice_params
    invalid_params[:candidates] =
      [@multi_choice_ballot.candidates.first.as_json] * (1 + MAX_CANDIDATES)

    assert_no_difference 'Ballot.count' do
      assert_no_difference 'Candidate.count' do
        post api_v1_ballots_url,
          headers: @authorized_headers,
          params: invalid_params
      end
    end

    assert_response :unprocessable_entity
  end

  test 'should not create multiple choice with fewer candidates than max selections' do
    [
      [@multi_choice_ballot.candidates.count, :created],
      [1 + @multi_choice_ballot.candidates.count, :unprocessable_entity],
    ].each do |max_candidate_ids_per_vote, expected_response|
      post api_v1_ballots_url,
        headers: @authorized_headers,
        params: @multi_choice_params.merge({
          ballot: @multi_choice_params[:ballot].merge({
            max_candidate_ids_per_vote: max_candidate_ids_per_vote
          })
        })
      assert_response expected_response
    end
  end

  test 'create multiple_choice should permit max_candidate_ids_per_vote' do
    assert_not_equal 1, @multi_choice_ballot.max_candidate_ids_per_vote

    post api_v1_ballots_url,
      headers: @authorized_headers,
      params: @multi_choice_params
    assert_response :created

    id = JSON.parse(response.body, symbolize_names: true)[:id]
    ballot = Ballot.find id
    assert_equal @multi_choice_ballot.max_candidate_ids_per_vote,
      ballot.max_candidate_ids_per_vote
  end

  test 'create yes_no should not permit max_candidate_ids_per_vote' do
    post api_v1_ballots_url,
      headers: @authorized_headers,
      params: @params.merge({
        ballot: @params[:ballot].merge({ max_candidate_ids_per_vote: 2 })
      })
    id = JSON.parse(response.body, symbolize_names: true)[:id]
    ballot = Ballot.find id
    assert_not_equal 2, ballot.max_candidate_ids_per_vote
  end

  test 'should not create any models if any candidate creation fails' do
    params = @params
    params[:candidates] = @ballot.candidates.as_json + [{ encrypted_title: 'bad' }]

    assert_no_difference 'Ballot.count' do
      assert_no_difference 'Candidate.count' do
        post api_v1_ballots_url, headers: @authorized_headers, params: params
      end
    end

    assert_response :unprocessable_entity
  end

  test 'should not create if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    post api_v1_ballots_url, headers: @authorized_headers, params: @params
    assert_response :not_found
  end

  test 'should index with valid authorization' do
    get api_v1_ballots_url, headers: @authorized_headers
    assert_response :ok
  end

  test 'should not index with invalid authorization' do
    get api_v1_ballots_url,
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'should not index if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get api_v1_ballots_url, headers: @authorized_headers
    assert_response :not_found
  end

  test 'index should only include ballots from requester Org' do
    get api_v1_ballots_url, headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    ballot_jsons = json_response.dig(:ballots)
    ballot_ids = ballot_jsons.map {|b| b[:id]}
    assert_not_equal 0, ballot_ids.length
    ballots = Ballot.find(ballot_ids)
    ballots.each do |ballot|
      assert_equal @user.org, ballot.org
    end
  end

  test 'index should format voting_ends_at attributes as iso8601' do
    get api_v1_ballots_url, headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    voting_ends_at = json_response.dig(:ballots, 0, :voting_ends_at)
    assert Time.iso8601(voting_ends_at)
  end

  test 'index should not include pagination metadata when page param is not included' do
    get api_v1_ballots_url, headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_nil json_response[:meta]
  end

  test 'index should include pagination metadata when page param is included' do
    get api_v1_ballots_url, headers: @authorized_headers, params: { page: 0 }
    json_response = JSON.parse(response.body, symbolize_names: true)
    metadata = json_response[:meta]
    assert json_response[:meta].key?(:current_page)
    assert json_response[:meta].key?(:next_page)
  end

  test 'index should respect page param' do
    page = 99
    get api_v1_ballots_url, headers: @authorized_headers, params: { page: page }
    json_response = JSON.parse(response.body, symbolize_names: true)
    current_page = json_response.dig(:meta, :current_page)
    assert_equal page, current_page
  end

  test 'should show ballots from request Org with valid auth' do
    assert_equal @ballot.org, @user.org

    get api_v1_ballot_url(@ballot), headers: @authorized_headers
    assert_response :ok
  end

  test 'show should only include allowed attributes' do
    get api_v1_ballot_url(@ballot), headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_only_includes_allowed_attributes json_response,
      Api::V1::BallotsController::ALLOWED_ATTRIBUTES,
      optional_attributes: [:results]
  end

  test 'show should not include results until voting ends' do
    travel_to @ballot.voting_ends_at - 1.second do
      get api_v1_ballot_url(@ballot),
        headers: authorized_headers(@user, Authenticatable::SCOPE_ALL)
      results = JSON.parse(response.body, symbolize_names: true)[:results]
      assert_nil results
    end

    travel_to @ballot.voting_ends_at do
      get api_v1_ballot_url(@ballot),
        headers: authorized_headers(@user, Authenticatable::SCOPE_ALL)
      results = JSON.parse(response.body, symbolize_names: true)[:results]
      assert_not_empty results
    end
  end

  test 'show should only include allowed ballot attributes' do
    get api_v1_ballot_url(@ballot), headers: @authorized_headers
    ballot = JSON.parse(response.body, symbolize_names: true)[:ballot]
    assert_only_includes_allowed_attributes ballot,
      Api::V1::BallotsController::ALLOWED_BALLOT_ATTRIBUTES
  end

  test 'show should only include allowed candidate attributes' do
    get api_v1_ballot_url(@ballot), headers: @authorized_headers
    candidates = JSON.parse(response.body, symbolize_names: true)[:candidates]
    candidates.each do |candidate|
      assert_only_includes_allowed_attributes candidate,
        Api::V1::BallotsController::ALLOWED_CANDIDATE_ATTRIBUTES
    end
  end

  test 'show should only include candidates for the requested ballot' do
    get api_v1_ballot_url(@ballot), headers: @authorized_headers
    response_json = JSON.parse(response.body, symbolize_names: true)
    candidate_jsons = response_json[:candidates]
    assert_not_equal 0, candidate_jsons.count
    assert_equal @ballot.candidates.ids.sort,
      candidate_jsons.map {|c| c[:id]}.sort
  end

  test 'should not show with invalid auth' do
    get api_v1_ballot_url(@ballot),
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'should not show for non-existent ballots' do
    get api_v1_ballot_url('bad-ballot_id'), headers: @authorized_headers
    assert_response :not_found
  end

  test 'should not show ballots in other Orgs' do
    ballot_in_another_org = ballots(:two)
    assert_not_equal @user.org, ballot_in_another_org.org
    get api_v1_ballot_url(ballot_in_another_org), headers: @authorized_headers
    assert_response :not_found
  end

  private

  def assert_only_includes_allowed_attributes(
    model, allowed_attributes, optional_attributes: []
  )
    model.keys.each do |key|
      assert allowed_attributes.include? key
    end

    required_attributes = allowed_attributes - optional_attributes
    required_attributes.each do |attribute|
      assert model.key? attribute
    end
  end
end
