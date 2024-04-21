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

  test 'should not create if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    @flaggable_urls.each do |url|
      assert_no_difference 'FlaggedItem.count' do
        post url, headers: @authorized_headers
      end

      assert_response :not_found
    end
  end

  test 'should not create on a nonexistent flaggable' do
    assert_equal @flaggable_urls.count, @nonexistent_flaggable_urls.count

    @nonexistent_flaggable_urls.each do |url|
      assert_no_difference 'FlaggedItem.count' do
        post url, headers: @authorized_headers
      end

      assert_response :not_found
    end
  end

  test 'should not create if flaggable belongs to another Org' do
    ballot_in_another_org = ballots :two
    assert_not_equal ballot_in_another_org.user.org.id, @user.org.id
    comment_in_another_org = comments :three
    assert_not_equal comment_in_another_org.post.org.id, @user.org.id
    post_in_another_org = posts :two
    assert_not_equal post_in_another_org.org.id, @user.org.id

    flaggable_urls_in_other_orgs = [
      api_v1_ballot_flagged_items_url(ballot_in_another_org),
      api_v1_comment_flagged_items_url(comment_in_another_org),
      api_v1_post_flagged_items_url(post_in_another_org),
    ]
    assert_equal @flaggable_urls.count, flaggable_urls_in_other_orgs.count

    flaggable_urls_in_other_orgs.each do |url|
      assert_no_difference 'FlaggedItem.count' do
        post url, headers: @authorized_headers
      end

      assert_response :not_found
    end
  end
end
