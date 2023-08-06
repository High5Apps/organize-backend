require "test_helper"

class Api::V1::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    p = posts(:one)
    @params = {
      post: p.attributes.with_indifferent_access.slice(
        *Api::V1::PostsController::PERMITTED_PARAMS,
      )
    }

    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, '*')
  end

  test 'should create with valid params' do
    assert_difference 'Post.count', 1 do
      post api_v1_posts_url, headers: @authorized_headers, params: @params
      assert_response :created
    end

    json_response = JSON.parse(response.body, symbolize_names: true)
    assert_not_nil json_response.dig(:id)
  end

  test 'should not create with invalid authorization' do
    assert_no_difference 'Post.count' do
      post api_v1_posts_url, headers: { Authorization: 'bad'}, params: @params
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    assert_no_difference 'Post.count' do
      post api_v1_posts_url, headers: @authorized_headers, params: {
        post: @params[:post].except(:title)
      }
      assert_response :unprocessable_entity
    end
  end

  test 'should not create if user is not in an org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    assert_no_difference 'Post.count' do
      post api_v1_posts_url, headers: @authorized_headers, params: @params
      assert_response :not_found
    end
  end
end
