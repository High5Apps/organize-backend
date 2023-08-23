require "test_helper"

class Api::V1::CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
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
end
