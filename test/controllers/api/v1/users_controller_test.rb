require "test_helper"

class Api::V1::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    user = users(:one)
    @params = {
      user: user.attributes.with_indifferent_access.slice(
        *Api::V1::UsersController::PERMITTED_PARAMS,
      ).merge(
        public_key: OpenSSL::PKey::RSA.new(user.public_key).to_s
      )
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
        user: @params[:user].except(:org_id)
      }
      assert_response :unprocessable_entity
    end
  end
end
