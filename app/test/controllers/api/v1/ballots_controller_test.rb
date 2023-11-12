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

  test 'create candidates should be optional' do
    params = @params.except(:candidates)

    assert_difference 'Ballot.count', 1 do
      assert_no_difference 'Candidate.count' do
        post api_v1_ballots_url, headers: @authorized_headers, params: params
      end
    end

    assert_response :created
  end
end
