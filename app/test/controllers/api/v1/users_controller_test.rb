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

  test 'index should be empty if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get api_v1_users_url, headers: @authorized_headers
    assert_pattern { response.parsed_body => users: [], meta:, **nil }
  end

  test 'index should only include users from requester Org' do
    get api_v1_users_url, headers: @authorized_headers
    user_ids = get_user_ids_from_response
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

  test 'index should not include blocked users' do
    user = users :blocked
    event = moderation_events(:four).dup
    unblock_all

    get api_v1_users_url, headers: @authorized_headers
    user_ids = get_user_ids_from_response

    all_user_ids = @user.org.users.ids
    assert_equal all_user_ids.sort, user_ids.sort

    [[:unblock, nil], [:block, user]].each do |action, blocked_user|
      user.send action

      get api_v1_users_url, headers: @authorized_headers
      user_ids = get_user_ids_from_response

      assert_equal (all_user_ids - [blocked_user&.id]).sort, user_ids.sort
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

  test 'show should only include ALLOWED_ATTRIBUTES for unblocked users' do
    assert_not @user_in_org.blocked?
    assert_not_includes User::Query::ALLOWED_ATTRIBUTES, :blocked

    get api_v1_user_url(@user_in_org), headers: @authorized_headers
    json_response = response.parsed_body

    attribute_allow_list = User::Query::ALLOWED_ATTRIBUTES
    assert_equal attribute_allow_list.count, json_response.keys.count
    attribute_allow_list.each do |attribute|
      assert json_response.key? attribute
      assert_not_nil json_response[attribute]
    end
  end

  test 'show should include blocked attribute for blocked users' do
    @user_in_org.block

    get api_v1_user_url(@user_in_org), headers: @authorized_headers
    json_response = response.parsed_body

    attribute_allow_list = User::Query::ALLOWED_ATTRIBUTES + [:blocked]
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

  # This is the only test covering the BlockedUserError handling in
  # ApplicationController#authenticate_user. Do not remove this test without
  # first adding a similar test to another controller.
  test 'should not show if requester is blocked' do
    @user.block
    get api_v1_user_url(@user_in_org), headers: @authorized_headers
    assert_response :forbidden
    response.parsed_body => error_messages: [/blocked/]
  end

  test 'show should include the same attributes as index for unblocked users' do
    assert_not @user.blocked?

    get api_v1_users_url, headers: @authorized_headers
    response.parsed_body => users:
    index_user = users.filter { |u| u[:id] === @user.id }.first

    get api_v1_user_url(@user), headers: @authorized_headers
    show_user = response.parsed_body
    assert_equal index_user, show_user
  end

  private

  def get_user_ids_from_response
    response.parsed_body => users: user_jsons
    user_jsons.map { |u| u[:id] }
  end
end
