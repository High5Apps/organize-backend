require "test_helper"

class Api::V1::PermissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @permission = permissions :one_edit_permissions

    @user = users :one
    setup_test_key(@user)
    @authorized_headers = authorized_headers @user, Authenticatable::SCOPE_ALL

    @non_officer = users :three
    setup_test_key(@non_officer)
  end

  test 'should show with valid authorization' do
    get show_by_scope_api_v1_permissions_url(@permission.scope),
      headers: @authorized_headers
    assert_response :ok
    assert_pattern do
      response.parsed_body => permission: { offices: [String, *], **nil }, **nil
    end
  end

  test 'should not show with invalid authorization' do
    get show_by_scope_api_v1_permissions_url(@permission.scope),
    headers: authorized_headers(@user,
      Authenticatable::SCOPE_ALL,
      expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'should not show unless user can view permissions' do
    assert_not @non_officer.can? :view_permissions
    get show_by_scope_api_v1_permissions_url(@permission.scope),
      headers: authorized_headers(@non_officer, Authenticatable::SCOPE_ALL)
    assert_response :unauthorized
  end

  test 'should not show if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get show_by_scope_api_v1_permissions_url(@permission.scope),
      headers: @authorized_headers
    assert_response :not_found
  end

  test 'should not show for non-existent scopes' do
    get show_by_scope_api_v1_permissions_url('bad_scope'),
      headers: @authorized_headers
    assert_response :not_found
  end
end
