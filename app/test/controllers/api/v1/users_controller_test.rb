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

    assert_pattern { response.parsed_body => id: String, **nil }
  end

  test 'should not create with invalid params' do
    assert_no_difference 'User.count' do
      post api_v1_users_url, params: {
        user: @params[:user].except(:public_key_bytes)
      }
      assert_response :unprocessable_entity
    end
  end

  test 'should index with valid authorization' do
    get api_v1_users_url, headers: @authorized_headers
    assert_response :ok
  end

  test 'should not index with invalid authorization' do
    get api_v1_users_url,
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'should not index if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get api_v1_users_url, headers: @authorized_headers
    assert_response :not_found
  end

  test 'index should only include users from requester Org' do
    get api_v1_users_url, headers: @authorized_headers
    response.parsed_body => users:
    user_ids = users.map { |u| u[:id] }
    assert_not_empty user_ids
    users = User.find(user_ids)
    users.each do |user|
      assert_equal @user.org, user.org
    end
  end

  test 'index should include pagination metadata by default' do
    get api_v1_users_url, headers: @authorized_headers
    assert_contains_pagination_data
  end

  test 'index should only include pagination metadata if query paginates' do
    filter = User::Query::PAGINATION_BYPASSING_FILTERS.first
    get api_v1_users_url, headers: @authorized_headers, params: { filter: }
    assert_not @controller.view_assigns['query'].paginates?
    assert_not_includes response.parsed_body, :meta
  end

  test 'index should respect page param' do
    page = 99
    get api_v1_users_url, headers: @authorized_headers, params: { page: }
    pagination_data = assert_contains_pagination_data
    assert_equal page, pagination_data[:current_page]
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
    json_response = response.parsed_body

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
