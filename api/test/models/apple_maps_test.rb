require "test_helper"

class AppleMapsTest < ActiveSupport::TestCase
  FAKE_ACCESS_TOKEN = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJpc3MiOiJtYXBzYXBpIiwidGlkIjoiMDEyMzQ1Njc4OSIsImFwcGlkIjoiMDEyMzQ1Njc4OS5tYXBzLmNvbS5leGFtcGxlLmFwcCIsIml0aSI6ZmFsc2UsImlydCI6ZmFsc2UsImlhdCI6MTc0MzEyMTg1OSwiZXhwIjoxNzQzMTIzNjU5fQ.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  FAKE_EXPIRES_IN_SECONDS = 1800
  FAKE_LATITUDE = 47.671234
  FAKE_LONGITUDE = -122.371234
  FAKE_QUERY = '5140 B'
  SEARCH_AUTOCOMPLETE_URI = \
    AppleMaps::BASE_URI + AppleMaps::SEARCH_AUTOCOMPLETE_PATH
  TOKEN_URI = AppleMaps::BASE_URI + AppleMaps::TOKEN_PATH

  setup do
    cache = ActiveSupport::Cache::MemoryStore.new

    key_pair = OpenSSL::PKey::EC.generate 'prime256v1'
    apple_maps = ActiveSupport::OrderedOptions.new.merge!({
      key_id: '123456',
      private_key: key_pair.private_to_pem,
      team_id: '987654',
    })
    @credentials = ActiveSupport::OrderedOptions.new.merge!(apple_maps:)

    sleep_method = ->(n) {}

    @apple_maps = AppleMaps.new cache:, sleep_method:, credentials: @credentials
  end

  test 'should stub external requests' do
    stub_token = stub_token_request
    stub_search = stub_search_request

    @apple_maps.search_autocomplete FAKE_QUERY, FAKE_LATITUDE, FAKE_LONGITUDE

    assert_requested stub_token
    assert_requested stub_search
  end

  test 'should request access_token if not in cache' do
    stub_token = stub_token_request
    stub_search_request

    @apple_maps.search_autocomplete FAKE_QUERY, FAKE_LATITUDE, FAKE_LONGITUDE

    assert_requested stub_token
  end

  test 'should not request token if cached token is not expired' do
    stub_token = stub_token_request
    stub_search_request

    10.times do
      @apple_maps.search_autocomplete FAKE_QUERY, FAKE_LATITUDE, FAKE_LONGITUDE
    end

    assert_requested stub_token, times: 1
  end

  test 'should request token if cached token is expired' do
    expiresInSeconds = FAKE_EXPIRES_IN_SECONDS
    stub_token = stub_token_request(expiresInSeconds:)
    stub_search_request

    @apple_maps.search_autocomplete FAKE_QUERY, FAKE_LATITUDE, FAKE_LONGITUDE
    travel 1 + expiresInSeconds
    @apple_maps.search_autocomplete FAKE_QUERY, FAKE_LATITUDE, FAKE_LONGITUDE

    assert_requested stub_token, times: 2
  end

  test 'should request token if cached token expires within RACE_CONDITION_TTL' do
    expiresInSeconds = FAKE_EXPIRES_IN_SECONDS
    stub_token = stub_token_request(expiresInSeconds:)
    stub_search_request

    @apple_maps.search_autocomplete FAKE_QUERY, FAKE_LATITUDE, FAKE_LONGITUDE
    travel 1 + expiresInSeconds - AppleMaps::RACE_CONDITION_TTL
    @apple_maps.search_autocomplete FAKE_QUERY, FAKE_LATITUDE, FAKE_LONGITUDE

    assert_requested stub_token, times: 2
  end

  test 'token request bearer token should include expected headers and payload' do
    stub_token_request
    stub_search_request

    freeze_time

    @apple_maps.search_autocomplete FAKE_QUERY, FAKE_LATITUDE, FAKE_LONGITUDE

    assert_requested :get, TOKEN_URI do |request|
      token = /Bearer (.+)/.match(request.headers['Authorization'])[1]
      decoded = JWT.decode(token, nil, false)
      headers = decoded[0]
      assert_equal headers, {
        exp: Time.now.to_i + AppleMaps::REFRESH_TOKEN_TTL.to_i,
        iat: Time.now.to_i,
        iss: @credentials.apple_maps.team_id,
      }.with_indifferent_access

      payload = decoded[1]
      assert_equal payload, {
        alg: AppleMaps::ALGORITHM,
        kid: @credentials.apple_maps.key_id,
        typ: AppleMaps::TYPE,
      }.with_indifferent_access
    end
  end

  test 'search_autocomplete request should include expected access_token' do
    stub_token_request
    stub_search_request

    @apple_maps.search_autocomplete FAKE_QUERY, FAKE_LATITUDE, FAKE_LONGITUDE

    assert_requested :get, SEARCH_AUTOCOMPLETE_URI,
        query: hash_including do |request|
      token = /Bearer (.+)/.match(request.headers['Authorization'])[1]
      assert_equal token, FAKE_ACCESS_TOKEN
    end
  end

  test 'search_autocomplete request should include expected query params' do
    stub_token_request
    stub_search_request

    query = FAKE_QUERY
    latitude = FAKE_LATITUDE
    longitude = FAKE_LONGITUDE
    @apple_maps.search_autocomplete query, latitude, longitude

    assert_requested :get, SEARCH_AUTOCOMPLETE_URI,
        query: hash_including do |request|
      assert_equal request.uri.query_values, {
        q: query,
        resultTypeFilter: AppleMaps::RESULT_TYPE_FILTER,
        limitToCountries: AppleMaps::LIMIT_TO_COUNTRIES,
        searchLocation: "#{latitude},#{longitude}",
        }.with_indifferent_access
    end
  end

  test 'search_autocomplete request should raise HTTParty error for unexpected error responses' do
    stub_token_request
    stub_search_request.to_return status: 500

    assert_raises HTTParty::Error do
      @apple_maps.search_autocomplete FAKE_QUERY, FAKE_LATITUDE, FAKE_LONGITUDE
    end
  end

  test 'search_autocomplete request should retry up to MAX_RETRIES times when response is unauthorized' do
    stub_token_request
    stub_search = stub_search_request.to_return status: 401

    @apple_maps.search_autocomplete FAKE_QUERY, FAKE_LATITUDE, FAKE_LONGITUDE

    assert_requested stub_search, times: 1 + AppleMaps::MAX_RETRIES
  end

  test 'search_autocomplete should return the response on success' do
    stub_token_request

    expected_response = { 'foo' => 'bar' }
    stub_search_request.to_return_json body: expected_response

    response = @apple_maps.search_autocomplete FAKE_QUERY, FAKE_LATITUDE,
      FAKE_LONGITUDE

    assert_equal expected_response, response
  end

  private

  def stub_token_request(body={})
    body.reverse_merge!({
      accessToken: FAKE_ACCESS_TOKEN,
      expiresInSeconds: FAKE_EXPIRES_IN_SECONDS,
    })
    stub_request(:get, TOKEN_URI).to_return_json(body:)
  end

  def stub_search_request
    stub_request(:get, SEARCH_AUTOCOMPLETE_URI).with query: hash_including
  end
end
