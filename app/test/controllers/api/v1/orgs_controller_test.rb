require "test_helper"

class Api::V1::OrgsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = orgs(:one)
    @params = { org: @org.attributes.as_json.with_indifferent_access }

    @other_org = orgs(:two)
    @update_params = {
      org: @other_org.attributes.as_json.with_indifferent_access }

    @user = users(:two)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)

    @user_in_org = users(:one)
    setup_test_key(@user_in_org)
  end

  test 'should create with valid params' do
    assert_difference 'Org.count', 1 do
      post api_v1_orgs_url, headers: @authorized_headers, params: @params
      assert_response :created
    end

    assert_pattern { response.parsed_body => id: String, **nil }
  end

  test 'should not create with invalid authorization' do
    assert_no_difference 'Org.count' do
      post api_v1_orgs_url,
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago),
      params: @params
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    assert_no_difference 'Org.count' do
      post api_v1_orgs_url, headers: @authorized_headers, params: {
        org: @params[:org].except(:encrypted_name)
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
    get api_v1_my_org_url,
      headers: authorized_headers(@user_in_org, Authenticatable::SCOPE_ALL)
    assert_response :ok

    assert_pattern do
      response.parsed_body => {
        encrypted_name:,
        encrypted_member_definition:,
        graph: {
          blocked_user_ids: [String, *],
          connections: [[String, String], *],
          user_ids: [String, *],
          **nil
        },
        id: String,
        **nil
      }
    end
  end

  test 'should not show my_org without authorization' do
    get api_v1_my_org_url
    assert_response :unauthorized
  end

  test 'should not show my_org with invalid authorization' do
    headers = authorized_headers @user_in_org,
      Authenticatable::SCOPE_ALL,
      expiration: 1.second.ago
    get(api_v1_my_org_url, headers:)
    assert_response :unauthorized
  end

  test 'my_org should return not_found when user has no org' do
    user_without_org = users(:two)
    assert_nil user_without_org.org

    get api_v1_my_org_url,
      headers: authorized_headers(user_without_org, Authenticatable::SCOPE_ALL)
    assert_response :not_found
  end

  test 'should update with valid params' do
    assert_changes -> { @org.reload.encrypted_name.attributes },
        from: @org.encrypted_name.attributes,
        to: @other_org.encrypted_name.attributes do
      assert_changes -> { @org.reload.encrypted_member_definition.attributes },
          from: @org.encrypted_member_definition.attributes,
          to: @other_org.encrypted_member_definition.attributes do
        patch(api_v1_update_my_org_url,
          headers: authorized_headers(@user_in_org, Authenticatable::SCOPE_ALL),
          params: @update_params)
      end
    end

    assert_response :ok
    assert_empty response.body
  end

  test 'should not update with invalid authorization' do
    assert_no_changes -> { @org.reload.encrypted_name.attributes } do
      assert_no_changes -> { @org.reload.encrypted_member_definition.attributes } do
        patch(api_v1_update_my_org_url,
          headers: authorized_headers(@user_in_org,
            Authenticatable::SCOPE_ALL,
            expiration: 1.second.ago),
          params: @update_params)
      end
    end

    assert_response :unauthorized
  end

  test 'should not update with invalid params' do
    assert_no_changes -> { @org.reload.encrypted_name.attributes } do
      assert_no_changes -> { @org.reload.encrypted_member_definition.attributes } do
        patch(api_v1_update_my_org_url,
          headers: authorized_headers(@user_in_org, Authenticatable::SCOPE_ALL),
          params: {})
      end
    end

    assert_response :unprocessable_entity
  end

  test 'should not update if user is not in an org' do
    @user_in_org.update!(org: nil)
    assert_nil @user_in_org.reload.org

    patch(api_v1_update_my_org_url,
      headers: authorized_headers(@user_in_org, Authenticatable::SCOPE_ALL),
      params: @update_params)

    assert_response :not_found
  end

  test 'should not update without permission' do
    user = users :three
    setup_test_key(user)
    assert_not user.can? :edit_org

    patch(api_v1_update_my_org_url,
      headers: authorized_headers(user, Authenticatable::SCOPE_ALL),
      params: @update_params)
    assert_response :unauthorized
  end
end
