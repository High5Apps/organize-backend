require "test_helper"

class V1::ConnectionsControllerTest < ActionDispatch::IntegrationTest
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
      post v1_connections_url, headers: @sharer_and_scanner_auth_headers
      assert_response :created
    end

    assert_pattern { response.parsed_body => id: String, **nil }
  end

  test 'should not create with invalid scanner auth' do
    assert_no_difference 'Connection.count' do
      post v1_connections_url,
        headers: @sharer_and_scanner_auth_headers
          .merge(Authenticatable::HEADER_AUTHORIZATION => 'bad')
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid sharer auth' do
    assert_no_difference 'Connection.count' do
      post v1_connections_url,
        headers: @sharer_and_scanner_auth_headers
          .merge(Authenticatable::HEADER_SHARER_AUTHORIZATION => 'bad')
      assert_response :unauthorized
    end
  end

  test 'should not create duplicate connections' do
    assert_difference 'Connection.count', 1 do
      post v1_connections_url, headers: @sharer_and_scanner_auth_headers
    end

    assert_no_difference 'Connection.count' do
      post v1_connections_url, headers: @sharer_and_scanner_auth_headers
    end
  end

  test 'should not create if sharer Org is not verified' do
    @sharer.org.update! verified_at: nil

    assert_no_difference 'Connection.count' do
      post v1_connections_url, headers: @sharer_and_scanner_auth_headers
    end

    assert_response :forbidden
    response.parsed_body => error_messages: [/verify/]
  end

  test 'should not create if sharer Org is behind on payments' do
    @sharer.org.update! behind_on_payments_at: Time.now.utc

    assert_no_difference 'Connection.count' do
      post v1_connections_url, headers: @sharer_and_scanner_auth_headers
    end

    assert_response :forbidden
    response.parsed_body => error_messages: [/payment/]
  end

  test 'should respond with ok when attempting to re-create' do
    post v1_connections_url, headers: @sharer_and_scanner_auth_headers
    post v1_connections_url, headers: @sharer_and_scanner_auth_headers
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
    post v1_connections_url, headers: reversed_headers
    assert_response :ok
  end

  test 'should update updated_at when attempting to re-create' do
    post v1_connections_url, headers: @sharer_and_scanner_auth_headers
    response.parsed_body => id:
    connection = Connection.find(id)
    assert_equal connection.created_at, connection.updated_at

    travel 1.second

    post v1_connections_url, headers: @sharer_and_scanner_auth_headers
    response.parsed_body => id:
    assert_operator connection.reload.created_at, :<, connection.updated_at
  end

  test "should preview" do
    get v1_connection_preview_url, headers: @sharer_auth_headers
    assert_response :ok

    assert_pattern do
      response.parsed_body => {
        org: {
          encrypted_name:,
          encrypted_member_definition:,
          id: String,
          **nil
        },
        user: { pseudonym:, **nil },
        **nil
      }
    end
  end

  test "should not preview without sharer auth" do
    get v1_connection_preview_url
    assert_response :unauthorized
  end

  test "should not preview with invalid sharer auth" do
    get v1_connection_preview_url,
      headers: { Authenticatable::HEADER_SHARER_AUTHORIZATION => 'bad' }
    assert_response :unauthorized
  end

  test "preview should return forbidden when sharer has no org" do
    assert_nil @scanner.org

    headers = authorized_headers @scanner,
      Authenticatable::SCOPE_CREATE_CONNECTIONS,
      header: Authenticatable::HEADER_SHARER_AUTHORIZATION
    get(v1_connection_preview_url, headers:)
    assert_response :forbidden
  end

  test 'should not preview if sharer Org is not verified' do
    @sharer.org.update! verified_at: nil

    get v1_connection_preview_url, headers: @sharer_auth_headers
    assert_response :forbidden
    response.parsed_body => error_messages: [/verify/]
  end

  test 'should not preview if sharer Org is behind on payments' do
    @sharer.org.update! behind_on_payments_at: Time.now.utc

    get v1_connection_preview_url, headers: @sharer_auth_headers
    assert_response :forbidden
    response.parsed_body => error_messages: [/payment/]
  end
end
