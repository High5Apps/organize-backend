require "test_helper"

class Api::V1::CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    @post_without_comments = posts(:three)
    @params = {
      comment: {
        body: 'Comment body',
      }
    }

    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, '*')

    @comment_with_upvotes = comments(:one)
  end

  test 'should create with valid params' do
    assert_difference 'Comment.count', 1 do
      post api_v1_post_comments_url(@post),
        headers: @authorized_headers,
        params: @params
    end

    assert_response :created

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_not_nil json_response.dig(:id)
  end

  test 'should not create with invalid authorization' do
    assert_no_difference 'Comment.count' do
      post api_v1_post_comments_url(@post),
        headers: { Authorization: 'bad'},
        params: @params
    end

    assert_response :unauthorized
  end

  test 'should not create with invalid params' do
    assert_no_difference 'Comment.count' do
      post api_v1_post_comments_url(@post),
        headers: @authorized_headers,
        params: { comment: @params[:comment].except(:body) }
    end

    assert_response :unprocessable_entity
  end

  test 'should not create on a nonexistent post' do
    assert_no_difference 'Comment.count' do
      post api_v1_post_comments_url('bad-post-id'),
        headers: @authorized_headers,
        params: @params
    end

    assert_response :not_found
  end

  test 'should not create if post belongs to another Org' do
    post_in_another_org = posts(:two)
    assert_not_equal post_in_another_org.org.id, @user.org.id

    assert_no_difference 'Comment.count' do
      post api_v1_post_comments_url(post_in_another_org),
        headers: @authorized_headers,
        params: @params
    end

    assert_response :not_found
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

    attribute_allow_list = Api::V1::CommentsController::ALLOWED_ATTRIBUTES.keys
    attribute_allow_list.each do |attribute|
      assert comment.key? attribute
    end

    assert_equal attribute_allow_list.count, comment.keys.count
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

  test "index should include my_vote as the requester's upvote value" do
    expected_vote = @user.upvotes
      .where(comment: @comment_with_upvotes).first.value
    assert_not_equal 0, expected_vote

    get api_v1_post_comments_url(@comment_with_upvotes.post),
      headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    comment_jsons = json_response.dig(:comments)
    comment = comment_jsons.find { |c| c[:id] == @comment_with_upvotes.id }
    vote = comment[:my_vote]
    assert_equal expected_vote, vote
  end

  test 'index should include my_vote as 0 when the user has not upvoted or downvoted' do
    comment_without_upvotes = comments(:two)
    assert_empty comment_without_upvotes.upvotes
    
    get api_v1_post_comments_url(comment_without_upvotes.post),
      headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    comment_jsons = json_response.dig(:comments)
    comment = comment_jsons.find { |c| c[:id] == comment_without_upvotes.id }
    vote = comment[:my_vote]
    assert_equal 0, vote
  end
end
