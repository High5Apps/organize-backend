require "test_helper"

class Api::V1::OfficesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)
  end

  test 'should index with valid authorization' do
    get api_v1_offices_url, headers: @authorized_headers
    assert_response :ok
  end

  test 'should not index with invalid authorization' do
    get api_v1_offices_url,
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'should not index if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get api_v1_offices_url, headers: @authorized_headers
    assert_response :forbidden
  end

  test 'index response open should match availability_in' do
    get api_v1_offices_url, headers: @authorized_headers

    # This doesn't use response.parsed_body because names need to be symbolized
    json_response = JSON.parse(response.body, symbolize_names: true)
    offices = json_response.dig(:offices)
    assert_equal Office.availability_in(@user.org), offices
  end
end
