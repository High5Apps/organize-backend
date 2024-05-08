require "test_helper"

class Api::V1::FlaggedItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @flaggable_urls = [
      api_v1_ballot_flagged_items_url(ballots :one),
      api_v1_comment_flagged_items_url(comments :one),
      api_v1_post_flagged_items_url(posts :one),
    ]
    @nonexistent_flaggable_urls = [
      api_v1_ballot_flagged_items_url('bad-ballot-id'),
      api_v1_comment_flagged_items_url('bad-comment-id'),
      api_v1_post_flagged_items_url('bad-post-id'),
    ]

    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)

    @other_user = users(:seven)
    setup_test_key(@other_user)
  end

  test 'should create with valid params' do
    @flaggable_urls.each do |url|
      assert_difference 'FlaggedItem.count', 1 do
        post url, headers: @authorized_headers
      end

      assert_response :created
      assert_empty response.body
    end
  end

  test 'should no-op when trying to double create' do
    [1, 0].each do |expected_difference|
      @flaggable_urls.each do |url|
        assert_difference 'FlaggedItem.count', expected_difference do
          post url, headers: @authorized_headers
          assert_response :created
        end
      end
    end
  end

  test 'should not create with invalid authorization' do
    @flaggable_urls.each do |url|
      assert_no_difference 'FlaggedItem.count' do
        post url,
          headers: authorized_headers(@user,
            Authenticatable::SCOPE_ALL,
            expiration: 1.second.ago)
      end

      assert_response :unauthorized
    end
  end

  test 'should index with valid authorization' do
    get api_v1_flagged_items_url, headers: @authorized_headers
    assert_response :ok
  end

  test 'should not index with invalid authorization' do
    get api_v1_flagged_items_url,
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'should not index if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get api_v1_flagged_items_url, headers: @authorized_headers
    assert_response :unauthorized
  end

  test 'should not index without permission' do
    assert_not @other_user.can? :moderate
    get api_v1_flagged_items_url,
      headers: authorized_headers(@other_user, Authenticatable::SCOPE_ALL)
    assert_response :unauthorized
  end

  test 'index should only include flagged items from requester Org' do
    get api_v1_flagged_items_url, headers: @authorized_headers
    response.parsed_body => flagged_items: flagged_item_jsons
    flagged_item_creator_ids = flagged_item_jsons.map { |fi| fi[:user_id] }
    assert_not_empty flagged_item_creator_ids
    flagged_item_creators = User.find flagged_item_creator_ids
    flagged_item_creators.each do |flagged_item_creator|
      assert_equal flagged_item_creator.org, @user.org
    end
  end

  test 'index should include pagination metadata' do
    get api_v1_flagged_items_url, headers: @authorized_headers
    assert_contains_pagination_data
  end

  test 'index should respect page param' do
    page = 99
    get api_v1_flagged_items_url,
      headers: @authorized_headers,
      params: { page: }
    pagination_data = assert_contains_pagination_data
    assert_equal page, pagination_data[:current_page]
  end
end
