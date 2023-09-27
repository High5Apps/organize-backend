require "test_helper"

class Api::V1::CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    comment = comments(:one)
    @commentable_urls = [
      api_v1_post_comments_url(@post),
      api_v1_comment_comments_url(comment),
    ]
    @post_without_comments = posts(:three)
    @params = {
      comment: {
        body: 'Comment body',
      }
    }

    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, '*')
  end

  test 'should create with valid params' do
    @commentable_urls.each do |url|
      assert_difference 'Comment.count', 1 do
        post url, headers: @authorized_headers, params: @params
      end

      assert_response :created

      json_response = JSON.parse(response.body, symbolize_names: true)
      assert_not_nil json_response.dig(:id)
    end
  end

  test 'should not create with invalid authorization' do
    @commentable_urls.each do |url|
      assert_no_difference 'Comment.count' do
        post url, headers: { Authorization: 'bad'}, params: @params
      end

      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    @commentable_urls.each do |url|
      assert_no_difference 'Comment.count' do
        post url,
          headers: @authorized_headers,
          params: { comment: @params[:comment].except(:body) }
      end

      assert_response :unprocessable_entity
    end
  end

  test 'should not create on a nonexistent commentable' do
    nonexistent_commentable_urls = [
      api_v1_post_comments_url('bad-post-id'),
      api_v1_comment_comments_url('bad-comment-id'),
    ]
    assert_equal @commentable_urls.count, nonexistent_commentable_urls.count

    nonexistent_commentable_urls.each do |url|
      assert_no_difference 'Comment.count' do
        post url, headers: @authorized_headers, params: @params
      end

      assert_response :not_found
    end
  end

  test 'should not create if post belongs to another Org' do
    post_in_another_org = posts(:two)
    assert_not_equal post_in_another_org.org.id, @user.org.id
    comment_in_another_org = comments(:three)
    assert_not_equal comment_in_another_org.post.org.id, @user.org.id
    commentable_urls_in_other_orgs = [
      api_v1_post_comments_url(post_in_another_org),
      api_v1_comment_comments_url(comment_in_another_org),
    ]
    assert_equal @commentable_urls.count, commentable_urls_in_other_orgs.count

    commentable_urls_in_other_orgs.each do |url|
      assert_no_difference 'Comment.count' do
        post url, headers: @authorized_headers, params: @params
      end

      assert_response :not_found
    end
  end

  test 'should index with valid authorization' do
    get api_v1_post_comments_url(@post), headers: @authorized_headers
    assert_response :ok
  end

  test 'should not index with invalid authorization' do
    get api_v1_post_comments_url(@post), headers: { Authorization: 'bad'}
    assert_response :unauthorized
  end

  test 'should not index on a nonexistent post' do
    get api_v1_post_comments_url('bad-post-id'), headers: @authorized_headers
    assert_response :not_found
  end

  test 'should not index if post belongs to another Org' do
    post_in_another_org = posts(:two)
    assert_not_equal post_in_another_org.org, @user.org

    get api_v1_post_comments_url(post_in_another_org),
      headers: @authorized_headers
    assert_response :not_found
  end

  test 'index should only include allow-listed attributes' do
    get api_v1_post_comments_url(@post), headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    comment = json_response.dig(:comments, 0)
    assert_only_includes_allowed_attributes comment
  end

  test 'index should format created_at attributes as floats' do
    get api_v1_post_comments_url(@post), headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    created_at = json_response.dig(:comments, 0, :created_at)
    assert_instance_of Float, created_at
  end

  test 'index should include multiple comments' do
    get api_v1_post_comments_url(@post), headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    comments = json_response.dig(:comments)
    assert_operator posts.count, :>, 1
  end

  test 'index should only include comments for the given post' do
    get api_v1_post_comments_url(@post), headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    comment_jsons = json_response.dig(:comments)
    comment_ids = comment_jsons.map {|comment| comment[:id]}
    comments = Comment.find(comment_ids)
    comments.each do |comment|
      assert_equal @post, comment.post
    end
  end

  test 'index should respect created_before param' do
    comment = comments(:two)
    post = comment.post
    created_before = comment.created_at.to_f

    get api_v1_post_comments_url(post),
      headers: @authorized_headers,
      params: { created_before: created_before }
    json_response = JSON.parse(response.body, symbolize_names: true)
    comment_jsons = json_response.dig(:comments)
    comment_created_ats = comment_jsons.map { |comment| comment[:created_at] }

    assert_not_empty comment_created_ats
    comment_created_ats.each do |created_at|
      assert_operator created_at, :<, created_before
    end
  end

  test 'index should include nested replies' do
    comment_with_reply = comments(:three)
    first_reply_id = comment_with_reply.children.first.id
    assert_not_empty first_reply_id

    post = comment_with_reply.post
    user = post.user
    setup_test_key(user)

    get api_v1_post_comments_url(post), headers: authorized_headers(user, '*')
    json_response = JSON.parse(response.body, symbolize_names: true)
    parent_comment = json_response.dig(:comments)
      .find { |c| c[:id] == comment_with_reply.id }
    replies = parent_comment[:replies]
    assert_not_empty replies

    reply = replies.find { |r| r[:id] == first_reply_id }
    assert_only_includes_allowed_attributes reply
  end

  private

  def assert_only_includes_allowed_attributes(comment)
    attribute_allow_list = Api::V1::CommentsController::ALLOWED_ATTRIBUTES
    assert_equal attribute_allow_list.count, comment.keys.count
    attribute_allow_list.each do |attribute|
      assert comment.key? attribute
    end
  end
end
