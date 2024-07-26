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
    @params = { comment: comment.attributes.as_json.with_indifferent_access }

    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)

    @comment_with_thread = comments(:four)
    @thread_user = users(:six)
    setup_test_key(@thread_user)
    @thread_authorized_headers = authorized_headers @thread_user,
      Authenticatable::SCOPE_ALL
  end

  test 'should create with valid params' do
    @commentable_urls.each do |url|
      assert_difference 'Comment.count', 1 do
        post url, headers: @authorized_headers, params: @params
      end

      assert_response :created
      assert_pattern { response.parsed_body => id: String, **nil }
    end
  end

  test 'should not create with invalid authorization' do
    @commentable_urls.each do |url|
      assert_no_difference 'Comment.count' do
        post url,
          headers: authorized_headers(@user,
            Authenticatable::SCOPE_ALL,
            expiration: 1.second.ago),
          params: @params
      end

      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    @commentable_urls.each do |url|
      assert_no_difference 'Comment.count' do
        post url,
          headers: @authorized_headers,
          params: { comment: @params[:comment].except(:encrypted_body) }
      end

      assert_response :unprocessable_entity
    end
  end

  test 'should index with valid authorization' do
    get api_v1_post_comments_url(@post), headers: @authorized_headers
    assert_response :ok
  end

  test 'should not index with invalid authorization' do
    get api_v1_post_comments_url(@post),
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
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

  test 'index should be empty if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get api_v1_post_comments_url(@post), headers: @authorized_headers
    assert_pattern { response.parsed_body => comments: [] }
  end

  test 'index should only include allow-listed attributes' do
    get api_v1_post_comments_url(@post), headers: @authorized_headers
    response.parsed_body => comments: [first_comment, *]
    assert_only_includes_allowed_attributes first_comment
  end

  test 'index should format created_at attributes as iso8601' do
    get api_v1_post_comments_url(@post), headers: @authorized_headers
    response.parsed_body => comments: [{ created_at: }, *]
    assert Time.iso8601(created_at)
  end

  test 'index should include multiple comments' do
    get api_v1_post_comments_url(@post), headers: @authorized_headers
    response.parsed_body => comments:
    assert_operator comments.count, :>, 1
  end

  test 'index should only include comments for the given post' do
    get api_v1_post_comments_url(@post), headers: @authorized_headers
    response.parsed_body => comments: comment_jsons
    comment_ids = comment_jsons.map {|comment| comment[:id]}
    comments = Comment.find(comment_ids)
    comments.each do |comment|
      assert_equal @post, comment.post
    end
  end

  test 'index should respect created_at_or_before param' do
    comment = comments(:two)
    post = comment.post
    created_at_or_before = comment.created_at.iso8601(6)

    get api_v1_post_comments_url(post),
      headers: @authorized_headers,
      params: { created_at_or_before: }
    response.parsed_body => comments: comment_jsons
    comment_created_ats = comment_jsons.map { |comment| comment[:created_at] }

    assert_not_empty comment_created_ats
    comment_created_ats.each do |created_at|
      assert_operator created_at, :<=, Time.iso8601(created_at_or_before)
    end
  end

  test 'index should include nested replies' do
    comment_with_reply = comments(:three)
    first_reply_id = comment_with_reply.children.first.id
    assert_not_empty first_reply_id

    post = comment_with_reply.post
    user = post.user
    setup_test_key(user)

    get api_v1_post_comments_url(post),
      headers: authorized_headers(user, Authenticatable::SCOPE_ALL)
    response.parsed_body => comments:
    parent_comment = comments.find { |c| c[:id] == comment_with_reply.id }
    replies = parent_comment[:replies]
    assert_not_empty replies

    reply = replies.find { |r| r[:id] == first_reply_id }
    assert_only_includes_allowed_attributes reply
  end

  test 'should get thread with valid authorization' do
    get thread_api_v1_comment_url(@comment_with_thread),
      headers: @thread_authorized_headers
    assert_response :ok
  end

  test 'should not get thread with invalid authorization' do
    get thread_api_v1_comment_url(@comment_with_thread),
      headers: authorized_headers(@thread_user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'should not get thread on a nonexistent comment' do
    get thread_api_v1_comment_url('bad-comment-id'),
      headers: @authorized_headers
    assert_response :not_found
  end

  test 'should not get thread if comment belongs to another Org' do
    user_in_another_org = @user
    assert_not_equal user_in_another_org, @comment_with_thread.post.org

    get thread_api_v1_comment_url(@comment_with_thread),
      headers: authorized_headers(@user, Authenticatable::SCOPE_ALL)
    assert_response :not_found
  end

  test 'should not get thread when user is not in an Org' do
    @thread_user.org = nil
    @thread_user.save validate: false
    assert_nil @thread_user.reload.org

    get thread_api_v1_comment_url(@comment_with_thread),
      headers: @thread_authorized_headers
    assert_response :not_found
  end

  test 'thread should only include allow-listed attributes' do
    get thread_api_v1_comment_url(@comment_with_thread),
      headers: @thread_authorized_headers
    response.parsed_body => thread:
    assert_only_includes_allowed_attributes thread
  end

  test 'thread should format created_at attributes as iso8601' do
    get thread_api_v1_comment_url(@comment_with_thread),
      headers: @thread_authorized_headers
    response.parsed_body => thread: { created_at: }
    assert Time.iso8601(created_at)
  end

  test 'thread should only return comments from the ancestry path' do
    get thread_api_v1_comment_url(@comment_with_thread),
      headers: @thread_authorized_headers
    response.parsed_body => thread:

    assert_nil @comment_with_thread.parent.parent
    assert_equal @comment_with_thread.parent.id, thread[:id]
    assert_equal 1, thread[:replies].count
    assert_equal @comment_with_thread.id, thread[:replies].first[:id]
    assert_empty @comment_with_thread.children
    assert_empty thread[:replies].first[:replies]
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
