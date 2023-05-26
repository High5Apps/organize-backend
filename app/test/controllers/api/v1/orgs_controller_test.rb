require "test_helper"

class Api::V1::OrgsControllerTest < ActionDispatch::IntegrationTest
  setup do
    org = orgs(:one)
    @params = {
      org: org.attributes.with_indifferent_access.slice(
        *Api::V1::OrgsController::PERMITTED_PARAMS,
      )
    }

    @user = users(:two)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, '*')

    @user_in_org = users(:one)
    setup_test_key(@user_in_org)
  end

  test 'should create with valid params' do
    assert_difference 'Org.count', 1 do
      post api_v1_orgs_url, headers: @authorized_headers, params: @params
      assert_response :created
    end

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_not_nil json_response.dig(:id)
  end

  test 'should not create with invalid authorization' do
    assert_no_difference 'Org.count' do
      post api_v1_orgs_url, headers: { Authorization: 'bad'}, params: @params
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    assert_no_difference 'Org.count' do
      post api_v1_orgs_url, headers: @authorized_headers, params: {
        org: @params[:org].except(:name)
      }
      assert_response :unprocessable_entity
    end
  end

  test "should set user's org_id on successful create" do
    assert_nil @user.pseudonym
    post api_v1_orgs_url, headers: @authorized_headers, params: @params
    assert_response :created
    assert_not_nil @user.reload.pseudonym
  end

  test 'should show graph' do
    org = @user_in_org.org
    get graph_api_v1_org_url(org),
      headers: authorized_headers(@user_in_org, '*')
    assert_response :ok

    body = JSON.parse(response.body, symbolize_names: true)
    assert_not_empty body.dig(:users)
    assert_not_empty body.dig(:connections)
  end

  test 'should not show graph with invalid authorization' do
    org = @user_in_org.org
    get graph_api_v1_org_url(org),
      headers: authorized_headers(@user_in_org, '*', 1.minute.ago)
    assert_response :unauthorized
  end
end
