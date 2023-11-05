require "test_helper"

class Api::V1::ConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sharer = users(:one)
    setup_test_key(@sharer)
    @scanner = users(:two)
    setup_test_key(@scanner)
    assert_not @sharer.directly_connected_to?(@scanner.id)

    @params = sharer_params(@sharer)
    @authorized_headers = authorized_headers(@scanner, '*')
  end

  test 'should create with valid params' do
    assert_difference 'Connection.count', 1 do
      post api_v1_connections_url, headers: @authorized_headers, params: @params
      assert_response :created
    end

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_not_nil json_response.dig(:id)
  end

  test 'should not create with invalid authorization' do
    assert_no_difference 'Connection.count' do
      post api_v1_connections_url,
        headers: @authorized_headers.merge(Authorization: 'bad'),
        params: @params
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid sharer_jwt' do
    assert_no_difference 'Connection.count' do
      post api_v1_connections_url,
        headers: @authorized_headers,
        params: sharer_params(@sharer, 1.minute.ago)
      assert_response :unauthorized
    end
  end

  test 'should not create duplicate connections' do
    assert_difference 'Connection.count', 1 do
      post api_v1_connections_url, headers: @authorized_headers, params: @params
    end

    assert_no_difference 'Connection.count' do
      post api_v1_connections_url, headers: @authorized_headers, params: @params
    end
  end

  test 'should respond with ok when attempting to re-create' do
    post api_v1_connections_url, headers: @authorized_headers, params: @params
    post api_v1_connections_url, headers: @authorized_headers, params: @params
    assert_response :ok
  end

  test 'should respond with ok when attempting to re-create in reverse' do
    connection = connections(:one)
    original_sharer = connection.sharer
    setup_test_key(original_sharer)
    original_scanner = connection.scanner
    setup_test_key(original_scanner)

    post api_v1_connections_url,
      headers: authorized_headers(original_sharer, '*'),
      params: sharer_params(original_scanner)
    assert_response :ok
  end

  test 'should update updated_at when attempting to re-create' do
    post api_v1_connections_url, headers: @authorized_headers, params: @params
    id = JSON.parse(response.body, symbolize_names: true).dig(:id)
    connection = Connection.find(id)
    assert_equal connection.created_at, connection.updated_at

    post api_v1_connections_url, headers: @authorized_headers, params: @params
    id = JSON.parse(response.body, symbolize_names: true).dig(:id)
    assert connection.reload.created_at < connection.updated_at
  end

  test "should preview" do
    get api_v1_connection_preview_url, params: @params
    assert_response :ok

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_not_nil json_response.dig(:org, :encrypted_name)
    assert_not_nil json_response.dig(:org, :encrypted_potential_member_definition)
    assert_not_nil json_response.dig(:org, :id)
    assert_not_nil json_response.dig(:org, :potential_member_definition)
    assert_not_nil json_response.dig(:user, :pseudonym)
  end

  test "should not preview without sharer_jwt" do
    get api_v1_connection_preview_url
    assert_response :unauthorized
  end

  test "should not preview with invalid sharer_jwt" do
    get api_v1_connection_preview_url,
      params: sharer_params(@sharer, 1.minute.ago)
    assert_response :unauthorized
  end

  test "preview should return not_found when sharer has no org" do
    assert_nil @scanner.org

    get api_v1_connection_preview_url, params: sharer_params(@scanner)
    assert_response :not_found
  end

  private

  def sharer_params(sharer, expiration=1.minute.from_now)
    sharer_jwt = sharer.create_auth_token(expiration, 'create:connections')
    { sharer_jwt: sharer_jwt }
  end
end
