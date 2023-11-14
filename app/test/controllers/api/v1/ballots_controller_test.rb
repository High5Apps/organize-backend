require "test_helper"

class Api::V1::BallotsControllerTest < ActionDispatch::IntegrationTest
  MAX_CANDIDATES = Api::V1::BallotsController::MAX_CANDIDATES_PER_CREATE

  setup do
    @ballot = ballots(:one)
    @params = {
      ballot: @ballot.as_json,
      candidates: @ballot.candidates.as_json,
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

  test 'should not create with more candidates than MAX_CANDIDATES_PER_CREATE' do
    valid_params = @params
    valid_params[:candidates] =
      [@ballot.candidates.first.as_json] * MAX_CANDIDATES
    post api_v1_ballots_url, headers: @authorized_headers, params: valid_params
    assert_response :created

    invalid_params = @params
    invalid_params[:candidates] =
      [@ballot.candidates.first.as_json] * (1 + MAX_CANDIDATES)

    assert_no_difference 'Ballot.count' do
      assert_no_difference 'Candidate.count' do
        post api_v1_ballots_url,
          headers: @authorized_headers,
          params: invalid_params
      end
    end

    assert_response :unprocessable_entity
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

  test 'create candidates should be optional' do
    params = @params.except(:candidates)

    assert_difference 'Ballot.count', 1 do
      assert_no_difference 'Candidate.count' do
        post api_v1_ballots_url, headers: @authorized_headers, params: params
      end
    end

    assert_response :created
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
end
