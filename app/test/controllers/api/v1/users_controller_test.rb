require "test_helper"

class Api::V1::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    setup_test_key(@user)
    @user_in_org = users(:three)
    @user_in_other_org = users(:two)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)
    @params = {
      user: @user.attributes.with_indifferent_access.slice(
        *Api::V1::UsersController::PERMITTED_PARAMS,
      ).merge(public_key_bytes: @user.public_key.to_pem)
    }
  end

  test 'should create with valid params' do
    assert_difference 'User.count', 1 do
      post api_v1_users_url, params: @params
      assert_response :created
    end

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_not_nil json_response.dig(:id)
  end

  test 'should not create with invalid params' do
    assert_no_difference 'User.count' do
      post api_v1_users_url, params: {
        user: @params[:user].except(:public_key_bytes)
      }
      assert_response :unprocessable_entity
    end
  end

  test 'should not show with invalid authorization' do
    get api_v1_user_url(@user_in_org),
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'should show users in the same Org with valid authorization' do
    assert_equal @user.org, @user_in_org.org

    get api_v1_user_url(@user_in_org), headers: @authorized_headers
    assert_response :ok
  end

  test 'show should only include ALLOWED_ATTRIBUTES' do
    get api_v1_user_url(@user_in_org), headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)

    attribute_allow_list = Api::V1::UsersController::ALLOWED_ATTRIBUTES
    assert_equal attribute_allow_list.count, json_response.keys.count
    attribute_allow_list.each do |attribute|
      assert json_response.key? attribute
      assert_not_nil json_response[attribute]
    end
  end

  test 'should not show users in other Orgs' do
    assert_not_equal @user.org, @user_in_other_org.org
    get api_v1_user_url(@user_in_other_org), headers: @authorized_headers
    assert_response :not_found
  end
end
