require "test_helper"

class Api::V1::ConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sharer = users(:one)
    setup_test_key(@sharer)
    @scanner = users(:two)
    setup_test_key(@scanner)
    assert_not @sharer.directly_connected_to?(@scanner.id)

    @sharer_auth_headers = authorized_headers @sharer,
      Authenticatable::SCOPE_CREATE_CONNECTIONS,
      header: Authenticatable::HEADER_SHARER_AUTHORIZATION
    @sharer_and_scanner_auth_headers = @sharer_auth_headers
      .merge authorized_headers(@scanner, Authenticatable::SCOPE_ALL)
  end

  test 'should create with valid auth' do
    assert_difference 'Connection.count', 1 do
      post api_v1_connections_url, headers: @sharer_and_scanner_auth_headers
      assert_response :created
    end

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_not_nil json_response.dig(:id)
  end

  test 'should not create with invalid scanner auth' do
    assert_no_difference 'Connection.count' do
      post api_v1_connections_url,
        headers: @sharer_and_scanner_auth_headers
          .merge(Authenticatable::HEADER_AUTHORIZATION => 'bad')
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid sharer auth' do
    assert_no_difference 'Connection.count' do
      post api_v1_connections_url,
        headers: @sharer_and_scanner_auth_headers
          .merge(Authenticatable::HEADER_SHARER_AUTHORIZATION => 'bad')
      assert_response :unauthorized
    end
  end

  test 'should not create duplicate connections' do
    assert_difference 'Connection.count', 1 do
      post api_v1_connections_url, headers: @sharer_and_scanner_auth_headers
    end

    assert_no_difference 'Connection.count' do
      post api_v1_connections_url, headers: @sharer_and_scanner_auth_headers
    end
  end

  test 'should respond with ok when attempting to re-create' do
    post api_v1_connections_url, headers: @sharer_and_scanner_auth_headers
    post api_v1_connections_url, headers: @sharer_and_scanner_auth_headers
    assert_response :ok
  end

  test 'should respond with ok when attempting to re-create in reverse' do
    connection = connections(:one)
    original_sharer = connection.sharer
    setup_test_key(original_sharer)
    original_scanner = connection.scanner
    setup_test_key(original_scanner)

    reversed_headers = authorized_headers(original_scanner,
      Authenticatable::SCOPE_CREATE_CONNECTIONS,
      header: Authenticatable::HEADER_SHARER_AUTHORIZATION
    ).merge(authorized_headers(original_sharer, Authenticatable::SCOPE_ALL))
    post api_v1_connections_url, headers: reversed_headers
    assert_response :ok
  end

  test 'should update updated_at when attempting to re-create' do
    post api_v1_connections_url, headers: @sharer_and_scanner_auth_headers
    id = JSON.parse(response.body, symbolize_names: true).dig(:id)
    connection = Connection.find(id)
    assert_equal connection.created_at, connection.updated_at

    post api_v1_connections_url, headers: @sharer_and_scanner_auth_headers
    id = JSON.parse(response.body, symbolize_names: true).dig(:id)
    assert connection.reload.created_at < connection.updated_at
  end

  test "should preview" do
    get api_v1_connection_preview_url, headers: @sharer_auth_headers
    assert_response :ok

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_not_nil json_response.dig(:org, :encrypted_name)
    assert_not_nil json_response.dig(:org, :encrypted_member_definition)
    assert_not_nil json_response.dig(:org, :id)
    assert_not_nil json_response.dig(:user, :pseudonym)
  end

  test "should not preview without sharer auth" do
    get api_v1_connection_preview_url
    assert_response :unauthorized
  end

  test "should not preview with invalid sharer auth" do
    get api_v1_connection_preview_url,
      headers: { Authenticatable::HEADER_SHARER_AUTHORIZATION => 'bad' }
    assert_response :unauthorized
  end

  test "preview should return not_found when sharer has no org" do
    assert_nil @scanner.org

    headers = authorized_headers @scanner,
      Authenticatable::SCOPE_CREATE_CONNECTIONS,
      header: Authenticatable::HEADER_SHARER_AUTHORIZATION
    get(api_v1_connection_preview_url, headers:)
    assert_response :not_found
  end
end
