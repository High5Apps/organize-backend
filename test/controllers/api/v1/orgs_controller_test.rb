require "test_helper"

class Api::V1::OrgsControllerTest < ActionDispatch::IntegrationTest
  setup do
    org = orgs(:one)
    @params = {
      org: org.attributes.with_indifferent_access.slice(
        *Api::V1::OrgsController::PERMITTED_PARAMS,
      )
    }
  end

  test 'should create with valid params' do
    assert_difference 'Org.count', 1 do
      post api_v1_orgs_url, params: @params
      assert_response :created
    end

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_not_nil json_response.dig(:id)
  end

  test 'should not create with invalid params' do
    assert_no_difference 'Org.count' do
      post api_v1_orgs_url, params: {
        org: @params[:org].except(:name)
      }
      assert_response :unprocessable_entity
    end
  end
end
