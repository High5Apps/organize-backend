require "test_helper"

class Api::V1::OrgsControllerTest < ActionDispatch::IntegrationTest
  setup do
    org = orgs(:one)
    @params = { org: org.attributes.as_json.with_indifferent_access }

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

  test 'should show my_org' do
    get api_v1_my_org_url, headers: authorized_headers(@user_in_org, '*')
    assert_response :ok

    body = JSON.parse(response.body, symbolize_names: true)
    assert_not_empty body.dig(:graph, :users)
    assert_not_empty body.dig(:graph, :connections)
    assert_not_empty body.dig(:id)
    assert_not_empty body.dig(:name)
    assert_not_empty body.dig(:potential_member_definition)
  end

  test 'should not show my_org without authorization' do
    get api_v1_my_org_url
    assert_response :unauthorized
  end

  test 'should not show my_org with invalid authorization' do
    get api_v1_my_org_url,
      headers: authorized_headers(@user_in_org, '*', 1.minute.ago)
    assert_response :unauthorized
  end

  test 'my_org should return not_found when user has no org' do
    user_without_org = users(:two)
    assert_nil user_without_org.org

    get api_v1_my_org_url, headers: authorized_headers(user_without_org, '*')
    assert_response :not_found
  end
end
