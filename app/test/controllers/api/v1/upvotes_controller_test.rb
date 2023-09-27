require "test_helper"

class Api::V1::UpvotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, '*')

    post = posts(:three)
    comment = comments(:two)
    @upvotable_urls = [
      api_v1_post_upvotes_url(post),
      api_v1_comment_upvotes_url(comment),
    ]

    @params = {
      upvote: {
        value: 1,
      }
    }
  end

  test 'should create with valid params' do
    @upvotable_urls.each do |url|
      assert_difference 'Upvote.count', 1 do
        post url, headers: @authorized_headers, params: @params
      end

      assert_response :created
    end
  end

  test 'should not create with invalid authorization' do
    @upvotable_urls.each do |url|
      assert_no_difference 'Upvote.count' do
        post url, headers: { Authorization: 'bad'}, params: @params
      end
  
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    @upvotable_urls.each do |url|
      assert_no_difference 'Upvote.count' do
        post url,
          headers: @authorized_headers,
          params: { upvote: @params[:upvote].except(:value) }
      end
  
      assert_response :unprocessable_entity
    end
  end

  test 'should not create on a nonexistent up-votable' do
    nonexistent_upvotable_urls = [
      api_v1_post_upvotes_url('non-existent-post-id'),
      api_v1_comment_upvotes_url('non-existent-comment-id'),
    ]
    assert_equal @upvotable_urls.count, nonexistent_upvotable_urls.count

    nonexistent_upvotable_urls.each do |url|
      assert_no_difference 'Upvote.count' do
        post url, headers: @authorized_headers, params: @params
      end
  
      assert_response :not_found
    end
  end

  test 'should not create if up-votable belongs to another Org' do
    post_in_another_org = posts(:two)
    assert_not_equal @user.org, post_in_another_org.org
    comment_in_another_org = comments(:three)
    assert_not_equal @user.org, comment_in_another_org.post.org
    upvotable_urls_in_other_orgs = [
      api_v1_post_upvotes_url(post_in_another_org),
      api_v1_comment_upvotes_url(comment_in_another_org),
    ]
    assert_equal @upvotable_urls.count, upvotable_urls_in_other_orgs.count

    upvotable_urls_in_other_orgs.each do |url|
      assert_no_difference 'Upvote.count' do
        post url, headers: @authorized_headers, params: @params
      end
    end

    assert_response :not_found
  end
end