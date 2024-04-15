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

    @election = ballots(:election_one)
    @election_params = {
      ballot: @election.attributes.merge(office: 'trustee').as_json,
    }

    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)

    @other_user = users(:three)
    setup_test_key(@other_user)
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

    assert_pattern { response.parsed_body => id: String, **nil }
  end

  test 'should not create with invalid authorization' do
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

  test 'should not create election with any candidates' do
    bad_params = @election_params.merge(candidates: @election.candidates.as_json)
    [
      [bad_params, :unprocessable_entity],
      [@election_params, :created],
    ].each do |params, expected_response|
      post api_v1_ballots_url,
        params:,
        headers: @authorized_headers
      assert_response expected_response
    end
  end

  test 'should not create election without permission' do
    assert_not @other_user.can? :create_elections
    post api_v1_ballots_url,
      headers: authorized_headers(@other_user, Authenticatable::SCOPE_ALL),
      params: @election_params
    assert_response :unauthorized
  end

  test 'should not create yes no without exactly 2 candidates' do
    4.times do |n|
      params = @params.merge(candidates: [@ballot.candidates.first.as_json] * n)
      post api_v1_ballots_url,
        params:,
        headers: @authorized_headers
        assert_response :unprocessable_entity unless n == 2
        assert_response :created if n == 2
    end
  end

  test 'should not create multiple choice with less than 2 candidates' do
    [nil, [], [@multi_choice_params[:candidates][0]]].each do |candidates|
      post api_v1_ballots_url,
        headers: @authorized_headers,
        params: @multi_choice_params.merge(candidates:)
      assert_response :unprocessable_entity
    end
  end

  test 'should not create multiple choice with more candidates than MAX_CANDIDATES_PER_CREATE' do
    invalid_params = @multi_choice_params.dup
    invalid_params[:candidates] =
      [@multi_choice_ballot.candidates.first.as_json] * (1 + MAX_CANDIDATES)

    valid_params = @multi_choice_params.dup
    valid_params[:candidates] =
      [@multi_choice_ballot.candidates.first.as_json] * MAX_CANDIDATES

    [
      [invalid_params, :unprocessable_entity, 0, 0],
      [valid_params, :created, 1, MAX_CANDIDATES],
    ].each do |params, expected_response, ballot_difference, candidate_difference|
      @multi_choice_ballot.candidates.destroy_all
      assert_difference 'Ballot.count', ballot_difference do
        assert_difference 'Candidate.count', candidate_difference do
          post api_v1_ballots_url,
            params:,
            headers: @authorized_headers
        end
      end

      assert_response expected_response
    end
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
            max_candidate_ids_per_vote:
          })
        })
      assert_response expected_response
    end
  end

  test 'should not create any models if any candidate creation fails' do
    params = @params
    params[:candidates] = @ballot.candidates.as_json + [{ encrypted_title: 'bad' }]

    assert_no_difference 'Ballot.count' do
      assert_no_difference 'Candidate.count' do
        post api_v1_ballots_url, headers: @authorized_headers, params:
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
    response.parsed_body => ballots: ballot_jsons
    ballot_ids = ballot_jsons.map {|b| b[:id]}
    assert_not_equal 0, ballot_ids.length
    ballots = Ballot.find(ballot_ids)
    ballots.each do |ballot|
      assert_equal @user.org, ballot.org
    end
  end

  test 'index should format voting_ends_at attributes as iso8601' do
    get api_v1_ballots_url, headers: @authorized_headers
    response.parsed_body => ballots: [{ voting_ends_at: }, *]
    assert Time.iso8601(voting_ends_at)
  end

  test 'index should not include pagination metadata when page param is not included' do
    get api_v1_ballots_url, headers: @authorized_headers
    assert_not_includes response.parsed_body, :meta
  end

  test 'index should include pagination metadata when page param is included' do
    get api_v1_ballots_url, headers: @authorized_headers, params: { page: 0 }
    assert_contains_pagination_data
  end

  test 'index should respect page param' do
    page = 99
    get api_v1_ballots_url, headers: @authorized_headers, params: { page: }
    pagination_data = assert_contains_pagination_data
    assert_equal page, pagination_data[:current_page]
  end

  test 'should show ballots from request Org with valid auth' do
    assert_equal @ballot.org, @user.org

    get api_v1_ballot_url(@ballot), headers: @authorized_headers
    assert_response :ok
  end

  test 'show should only include allowed attributes' do
    get api_v1_ballot_url(@ballot), headers: @authorized_headers
    assert_only_includes_allowed_attributes response.parsed_body,
      Api::V1::BallotsController::ALLOWED_ATTRIBUTES,
      optional_attributes: [:nominations, :results, :terms]
  end

  test 'show should only include nominations for elections' do
    [[@election, true], [@ballot, false]].each do |ballot, expect_nominations|
      get api_v1_ballot_url(ballot), headers: @authorized_headers
      nominations = response.parsed_body[:nominations]
      assert_nil(nominations) unless expect_nominations
      assert_not_nil(nominations) if expect_nominations
    end
  end

  test 'show should only include allowed nominations attributes' do
    travel_to @election.nominations_end_at - 1.second do
      get api_v1_ballot_url(@election),
        # Can't use @authorized_headers due to travel_to
        headers: authorized_headers(@user, Authenticatable::SCOPE_ALL)
    end

    response.parsed_body => nominations:
    assert_not_empty nominations
    nominations.each do |nomination|
      assert_only_includes_allowed_attributes nomination,
        Api::V1::BallotsController::ALLOWED_NOMINATION_ATTRIBUTES

      [nomination[:nominator], nomination[:nominee]].each do |user|
        assert_only_includes_allowed_attributes user,
          Api::V1::BallotsController::ALLOWED_NOMINATION_USER_ATTRIBUTES
      end
    end
  end

  test 'show should not include results until voting ends' do
    travel_to @ballot.voting_ends_at - 1.second do
      get api_v1_ballot_url(@ballot),
        # Can't use @authorized_headers due to travel_to
        headers: authorized_headers(@user, Authenticatable::SCOPE_ALL)
      assert_not_includes response.parsed_body, :results
    end

    travel_to @ballot.voting_ends_at do
      get api_v1_ballot_url(@ballot),
        # Can't use @authorized_headers due to travel_to
        headers: authorized_headers(@user, Authenticatable::SCOPE_ALL)
      assert_not_empty response.parsed_body[:results]
    end
  end

  test 'show should only include allowed results attributes' do
    travel_to @ballot.voting_ends_at do
      get api_v1_ballot_url(@ballot),
        # Can't use @authorized_headers due to travel_to
        headers: authorized_headers(@user, Authenticatable::SCOPE_ALL)
    end

    response.parsed_body => results:
    assert_not_empty results
    results.each do |result|
      assert_only_includes_allowed_attributes result,
        Api::V1::BallotsController::ALLOWED_RESULTS_ATTRIBUTES
    end
  end

  test 'show should not include terms until voting ends' do
    [
      [@election.voting_ends_at - 1.second, false],
      [@election.voting_ends_at, true],
    ].each do |time, expected_presence|
      travel_to time do
        get api_v1_ballot_url(@election),
          headers: authorized_headers(@user, Authenticatable::SCOPE_ALL)
        terms = response.parsed_body[:terms]
        assert_not_nil terms if expected_presence
        assert_nil terms unless expected_presence
      end
    end
  end

  test 'show should only include allowed terms attributes' do
    election_with_term = ballots :election_president
    travel_to election_with_term.voting_ends_at do
      get api_v1_ballot_url(election_with_term),
        # Can't use @authorized_headers due to travel_to
        headers: authorized_headers(@user, Authenticatable::SCOPE_ALL)
    end

    response.parsed_body => terms:
    assert_not_empty terms
    terms.each do |term|
      assert_only_includes_allowed_attributes term,
        Api::V1::BallotsController::ALLOWED_TERMS_ATTRIBUTES
    end
  end

  test 'show should only include allowed ballot attributes for non-elections' do
    get api_v1_ballot_url(@ballot), headers: @authorized_headers
    response.parsed_body => ballot:
    assert_only_includes_allowed_attributes ballot,
      Api::V1::BallotsController::ALLOWED_BALLOT_ATTRIBUTES
  end

  test 'show should only include allowed ballot attributes for elections' do
    get api_v1_ballot_url(@election), headers: @authorized_headers
    response.parsed_body => ballot:
    assert_only_includes_allowed_attributes ballot,
      Api::V1::BallotsController::ALLOWED_BALLOT_ELECTION_ATTRIBUTES
  end

  test 'show should only include allowed candidate attributes' do
    assert_not @ballot.election?
    assert_not @multi_choice_ballot.election?
    assert @election.election?

    [
      [
        @ballot,
        Api::V1::BallotsController::ALLOWED_NON_ELECTION_CANDIDATE_ATTRIBUTES,
      ],
      [
        @multi_choice_ballot,
        Api::V1::BallotsController::ALLOWED_NON_ELECTION_CANDIDATE_ATTRIBUTES,
      ],
      [
        @election,
        Api::V1::BallotsController::ALLOWED_ELECTION_CANDIDATE_ATTRIBUTES,
      ],
    ].each do |ballot, attributes|
      get api_v1_ballot_url(ballot), headers: @authorized_headers
      response.parsed_body => candidates:
      candidates.each do |candidate|
        assert_only_includes_allowed_attributes candidate, attributes
      end
    end
  end

  test 'show should only include candidates for the requested ballot' do
    get api_v1_ballot_url(@ballot), headers: @authorized_headers
    response.parsed_body => candidates: candidate_jsons
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

  test 'show should format refreshed_at as iso8601' do
    get api_v1_ballot_url(@ballot), headers: @authorized_headers
    response.parsed_body => refreshed_at:
    assert Time.iso8601(refreshed_at)
  end

  private

  def assert_only_includes_allowed_attributes(
    model, allowed_attributes, optional_attributes: []
  )
    model.keys.each do |key|
      assert_includes allowed_attributes, key.to_sym
    end

    required_attributes = allowed_attributes - optional_attributes
    required_attributes.each do |attribute|
      assert_includes model, attribute
    end
  end
end
