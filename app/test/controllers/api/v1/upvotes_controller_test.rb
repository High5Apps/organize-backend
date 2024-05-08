require "test_helper"

class Api::V1::UpvotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)

    post = posts(:three)
    comment = comments(:two)
    @upvotables = [post, comment]
    @upvotable_urls = [
      api_v1_post_upvotes_url(post),
      api_v1_comment_upvotes_url(comment),
    ]

    @params = create_params value: 1
  end

  test 'should create with valid params' do
    @upvotable_urls.each do |url|
      assert_difference 'Upvote.count', 1 do
        post url, headers: @authorized_headers, params: @params
      end

      assert_response :created
    end
  end

  test 'should update when attempting to double create' do
    @upvotables.each_with_index do |upvotable, i|
      url = @upvotable_urls[i]
      assert_changes -> { upvotable.upvotes.sum(:value) }, from: 0, to: 1 do
        assert_difference 'Upvote.count', 1 do
          post url,
            headers: @authorized_headers,
            params: create_params(value: 1)
          assert_response :created
        end
      end

      assert_changes -> { upvotable.upvotes.sum(:value) }, from: 1, to: 0 do
        assert_no_difference 'Upvote.count' do
          post url,
            headers: @authorized_headers,
            params: create_params(value: 0)
          assert_response :created
        end
      end
    end
  end

  test 'should not create with invalid authorization' do
    @upvotable_urls.each do |url|
      assert_no_difference 'Upvote.count' do
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
    @upvotable_urls.each do |url|
      assert_no_difference 'Upvote.count' do
        post url,
          headers: @authorized_headers,
          params: { upvote: @params[:upvote].except(:value) }
      end

      assert_response :unprocessable_entity
    end
  end

  private

  def create_params value:
    { upvote: { value: } }
  end
end
