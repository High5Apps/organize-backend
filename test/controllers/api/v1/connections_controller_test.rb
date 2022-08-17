require "test_helper"

class Api::V1::ConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sharer = users(:one)
    setup_test_key(sharer)
    scanner = users(:two)
    setup_test_key(scanner)
    assert_not sharer.directly_connected_to?(scanner.id)

    @params = {
      sharer_jwt: sharer.create_auth_token(1.minute.from_now),
    }

    @authorized_headers = {
      Authorization: scanner.create_auth_token(1.minute.from_now),
    }
  end

  test 'should create with valid params' do
    assert_difference 'Connection.count', 1 do
      post api_v1_connections_url, headers: @authorized_headers, params: @params
      assert_response :created
    end
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
        params: @params.merge(sharer_jwt: 'bad')
      assert_response :unauthorized
    end
  end
end
