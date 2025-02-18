require "test_helper"

class V1::OrgsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = orgs(:one)
    org_attributes = @org.as_json.with_indifferent_access
      .merge(email: random_email)
    @params = { org: org_attributes }

    @other_org = orgs(:two)
    other_org_attributes = @other_org.as_json.with_indifferent_access
      .merge(email: random_email)
    @update_params = { org: other_org_attributes }

    @user = users(:two)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)

    @user_in_org = users(:one)
    setup_test_key(@user_in_org)

    @non_officer = users(:three)
    setup_test_key(@non_officer)
  end

  test 'should create with valid params' do
    assert_difference 'Org.count', 1 do
      post v1_orgs_url, headers: @authorized_headers, params: @params
      assert_response :created
    end

    assert_pattern { response.parsed_body => id: String, **nil }
  end

  test 'should not create with invalid authorization' do
    assert_no_difference 'Org.count' do
      post v1_orgs_url,
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago),
      params: @params
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    assert_no_difference 'Org.count' do
      post v1_orgs_url, headers: @authorized_headers, params: {
        org: @params[:org].except(:encrypted_name)
      }
      assert_response :unprocessable_entity
    end
  end

  test "should set user's org_id on successful create" do
    assert_nil @user.pseudonym
    post v1_orgs_url, headers: @authorized_headers, params: @params
    assert_response :created
    assert_not_nil @user.reload.pseudonym
  end

  test 'should show my_org' do
    get v1_my_org_url,
      headers: authorized_headers(@user_in_org, Authenticatable::SCOPE_ALL)
    assert_response :ok

    # email is only included when requester can edit_org
    assert @user_in_org.can? :edit_org

    assert_pattern do
      response.parsed_body => {
        email: String,
        encrypted_employer_name:,
        encrypted_name:,
        encrypted_member_definition:,
        graph: {
          blocked_user_ids: [String, *],
          connections: [[String, String], *],
          left_org_user_ids: [String, *],
          user_ids: [String, *],
          **nil
        },
        id: String,
        **nil
      }
    end
  end

  test 'should not show my_org without authorization' do
    get v1_my_org_url
    assert_response :unauthorized
  end

  test 'should not show my_org with invalid authorization' do
    headers = authorized_headers @user_in_org,
      Authenticatable::SCOPE_ALL,
      expiration: 1.second.ago
    get(v1_my_org_url, headers:)
    assert_response :unauthorized
  end

  test 'should not show my_org when user has no org' do
    user_without_org = users(:two)
    assert_nil user_without_org.org

    get v1_my_org_url,
      headers: authorized_headers(user_without_org, Authenticatable::SCOPE_ALL)
    assert_response :forbidden
  end

  test 'my_org should not include email unless requester can edit_org' do
    [[@non_officer, false], [@user_in_org, true]].each do |user, includes_email|
      assert_equal user.can?(:edit_org), includes_email
      get v1_my_org_url,
        headers: authorized_headers(user, Authenticatable::SCOPE_ALL)
      assert_equal response.parsed_body.include?(:email), includes_email
    end
  end

  test 'should update with valid params' do
    assert_changes -> { @org.reload.encrypted_name.attributes },
        from: @org.encrypted_name.attributes,
        to: @other_org.encrypted_name.attributes do
      assert_changes -> { @org.reload.encrypted_member_definition.attributes },
          from: @org.encrypted_member_definition.attributes,
          to: @other_org.encrypted_member_definition.attributes do
        patch(v1_update_my_org_url,
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
        patch(v1_update_my_org_url,
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
        patch(v1_update_my_org_url,
          headers: authorized_headers(@user_in_org, Authenticatable::SCOPE_ALL),
          params: {})
      end
    end

    assert_response :unprocessable_entity
  end

  test 'should not update if user is not in an org' do
    @user_in_org.update!(org: nil)
    assert_nil @user_in_org.reload.org

    patch(v1_update_my_org_url,
      headers: authorized_headers(@user_in_org, Authenticatable::SCOPE_ALL),
      params: @update_params)

    assert_response :forbidden
  end

  test 'should not update if Org is not verified' do
    @user_in_org.org.update! verified_at: nil

    patch(v1_update_my_org_url,
      headers: authorized_headers(@user_in_org, Authenticatable::SCOPE_ALL),
      params: @update_params)

    assert_response :forbidden
  end

  test 'should not update if Org is behind on payments' do
    @user_in_org.org.update! behind_on_payments_at: Time.now.utc

    patch(v1_update_my_org_url,
      headers: authorized_headers(@user_in_org, Authenticatable::SCOPE_ALL),
      params: @update_params)

    assert_response :forbidden
  end

  test 'should not update without permission' do
    user = users :three
    setup_test_key(user)
    assert_not user.can? :edit_org

    patch(v1_update_my_org_url,
      headers: authorized_headers(user, Authenticatable::SCOPE_ALL),
      params: @update_params)
    assert_response :forbidden
  end

  test 'should verify with valid authorization' do
    post v1_verify_url,
      headers: authorized_headers(@user_in_org, Authenticatable::SCOPE_ALL),
      params: { code: @org.verification_code }
    assert_response :ok
  end

  test 'should not verify with invalid authorization' do
    post v1_verify_url,
      headers: authorized_headers(@user_in_org,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago),
      params: { code: @org.verification_code }
    assert_response :unauthorized
  end

  test 'verify should return forbidden with invalid code' do
    post v1_verify_url,
      headers: authorized_headers(@user_in_org, Authenticatable::SCOPE_ALL),
      params: { code: 'invalid' }
    assert_response :forbidden
  end

  test 'verify should be idempotent' do
    2.times do
      post v1_verify_url,
        headers: authorized_headers(@user_in_org, Authenticatable::SCOPE_ALL),
        params: { code: @org.verification_code }
      assert_response :ok
    end
  end

  test 'should not verify if user is not in an org' do
    @user_in_org.update!(org: nil)
    assert_nil @user_in_org.reload.org

    post v1_verify_url,
      headers: authorized_headers(@user_in_org, Authenticatable::SCOPE_ALL),
      params: { code: @org.verification_code }
    assert_response :forbidden
  end
end
