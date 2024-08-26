require "test_helper"

class Api::V1::PermissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @permission = permissions :one_edit_permissions
    @other_permission = @permission.dup
    @other_permission.update! scope: :create_elections
    @scopes = [@permission.scope, @other_permission.scope]

    @user = users :one
    setup_test_key(@user)
    @authorized_headers = authorized_headers @user, Authenticatable::SCOPE_ALL

    @non_officer = users :three
    setup_test_key(@non_officer)
  end

  test 'should create with valid params' do
    @permission.destroy!

    assert_difference 'Permission.count', 1 do
      post create_by_scope_api_v1_permissions_url(@permission.scope),
        headers: @authorized_headers,
        params: create_params
    end

    assert_response :created
    assert_empty response.body
  end

  test 'should update when attempting to double create' do
    @permission.destroy!
    [
      [['founder', 'president', 'secretary'], 1],
      [['founder', 'president'], 0],
    ].each do |expected_offices, difference|
      assert_difference 'Permission.count', difference do
        post create_by_scope_api_v1_permissions_url(@permission.scope),
          headers: @authorized_headers,
          params: create_params(expected_offices)
        assert_response :created
        offices = @permission.org.permissions.find_by(scope: @permission.scope)
          .data.offices
        assert_equal expected_offices, offices
      end
    end
  end

  test 'should not create with invalid authorization' do
    post create_by_scope_api_v1_permissions_url(@permission.scope),
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago),
      params: create_params
    assert_response :unauthorized
  end

  test 'should not create with invalid params' do
    post create_by_scope_api_v1_permissions_url(@permission.scope),
      headers: @authorized_headers,
      params: create_params([:bad_office])

    assert_response :unprocessable_entity
  end

  test 'should not create if user is not in an org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    post create_by_scope_api_v1_permissions_url(@permission.scope),
      headers: @authorized_headers,
      params: create_params

    assert_response :forbidden
  end

  test 'should not create if Org is not verified' do
    @user.org.update! verified_at: nil

    post create_by_scope_api_v1_permissions_url(@permission.scope),
      headers: @authorized_headers,
      params: create_params

    assert_response :forbidden
  end

  test 'should not create unless user can edit permissions' do
    assert_not @non_officer.can? :edit_permissions
    post create_by_scope_api_v1_permissions_url(@permission.scope),
      headers: authorized_headers(@non_officer, Authenticatable::SCOPE_ALL),
      params: create_params
    assert_response :forbidden
  end

  test 'should not create for non-existent scopes' do
    get create_by_scope_api_v1_permissions_url('bad_scope'),
      headers: @authorized_headers,
      params: create_params
    assert_response :not_found
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

  test 'should not show unless user can edit permissions' do
    assert_not @non_officer.can? :edit_permissions
    get show_by_scope_api_v1_permissions_url(@permission.scope),
      headers: authorized_headers(@non_officer, Authenticatable::SCOPE_ALL)
    assert_response :forbidden
  end

  test 'should not show if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get show_by_scope_api_v1_permissions_url(@permission.scope),
      headers: @authorized_headers
    assert_response :forbidden
  end

  test 'should not show for non-existent scopes' do
    get show_by_scope_api_v1_permissions_url('bad_scope'),
      headers: @authorized_headers
    assert_response :not_found
  end

  test 'should index my_permissions with valid authorization' do
    get api_v1_index_my_permissions_url,
      headers: @authorized_headers,
      params: { scopes: @scopes }
    assert_response :ok

    assert_pattern do
      response.parsed_body => {
        my_permissions: [{
          permitted: (true | false),
          scope: String,
          **nil
        }, *],
        **nil
      }
    end
  end

  test 'index my_permissions permitted should match authenticated_user.can?' do
    [
      [[:founder], true],
      [[], false],
    ].each do |offices, expected_permitted|
      @scopes.each do |scope|
        permission = @user.org.permissions.find_by(scope:)
        permission.data = { offices: }
        permission.save! validate: false

        assert_equal expected_permitted, @user.can?(scope)
      end

      get api_v1_index_my_permissions_url,
        headers: @authorized_headers,
        params: { scopes: @scopes }
      response.parsed_body => my_permissions:

      my_permissions.each do |my_permission|
        my_permission => permitted:
        assert_equal expected_permitted, permitted
      end
    end
  end

  test 'index my_permissions should run for all scopes when no scopes param is given' do
    get api_v1_index_my_permissions_url,
      headers: @authorized_headers
    response.parsed_body => my_permissions:
    assert_equal Permission::SCOPE_SYMBOLS.count, my_permissions.count
    assert_empty \
      my_permissions.map { |p| p[:scope].to_sym } - Permission::SCOPE_SYMBOLS
  end

  test 'should not index my_permissions with invalid authorization' do
    get api_v1_index_my_permissions_url,
    headers: authorized_headers(@user,
      Authenticatable::SCOPE_ALL,
      expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'should not index my_permissions if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get api_v1_index_my_permissions_url,
      headers: @authorized_headers
    assert_response :forbidden
  end

  test 'index my_permissions should return false for non-existent scopes' do
    get api_v1_index_my_permissions_url,
      headers: @authorized_headers,
      params: { scopes: [@permission.scope, 'bad_scope'] }
    assert_response :ok

    response.parsed_body => my_permissions:
    assert_equal [true, false], my_permissions.map { |p| p[:permitted] }
  end

  private

  def create_params(offices = @permission.data.offices)
    { permission: { offices: } }
  end
end
