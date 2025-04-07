require "test_helper"

class V1::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    @params = { post: @post.attributes.as_json.with_indifferent_access }

    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)
  end

  test 'should create with valid params' do
    assert_difference 'Post.count', 1 do
      post v1_posts_url, headers: @authorized_headers, params: @params
      assert_response :created
    end

    response.parsed_body => { id: String, created_at:, **nil }
    assert Time.iso8601(created_at)
  end

  test 'should not create with invalid authorization' do
    assert_no_difference 'Post.count' do
      post v1_posts_url,
        headers: authorized_headers(@user,
          Authenticatable::SCOPE_ALL,
          expiration: 1.second.ago),
        params: @params
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    assert_no_difference 'Post.count' do
      post v1_posts_url, headers: @authorized_headers, params: {
        post: @params[:post].except(:category)
      }
      assert_response :unprocessable_entity
    end
  end

  test 'should index with valid authorization' do
    get v1_posts_url, headers: @authorized_headers
    assert_response :ok
  end

  test 'should not index with invalid authorization' do
    get v1_posts_url,
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'should not index if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get v1_posts_url, headers: @authorized_headers
    assert_response :forbidden
  end

  test 'should not index if Org is not verified' do
    @user.org.update! verified_at: nil
    get v1_posts_url, headers: @authorized_headers
    assert_response :forbidden
  end

  test 'should not index if Org is behind on payments' do
    @user.org.update! behind_on_payments_at: Time.now.utc
    get v1_posts_url, headers: @authorized_headers
    assert_response :forbidden
  end

  test 'index should include multiple posts' do
    get v1_posts_url, headers: @authorized_headers
    response.parsed_body => posts:
    assert_operator posts.count, :>, 1
  end

  test 'index should only include posts from requester Org' do
    get v1_posts_url, headers: @authorized_headers
    post_ids = get_post_ids_from_response
    posts = Post.find(post_ids)
    assert_not_empty posts
    posts.each do |post|
      assert_equal post.org, @user.org
    end
  end

  test 'index should format created_at attributes as iso8601' do
    get v1_posts_url, headers: @authorized_headers
    response.parsed_body => posts: [{ created_at: }, *]
    assert Time.iso8601(created_at)
  end

  test 'index should include pagination metadata' do
    get v1_posts_url, headers: @authorized_headers
    assert_contains_pagination_data
  end

  test 'index should respect page param' do
    page = 99
    get v1_posts_url, headers: @authorized_headers, params: { page: }
    pagination_data = assert_contains_pagination_data
    assert_equal page, pagination_data[:current_page]
  end

  test 'index should not include blocked posts' do
    flagged_post = posts :one
    event = moderation_events(:one).dup
    unblock_all

    get v1_posts_url, headers: @authorized_headers
    post_ids = get_post_ids_from_response

    all_post_ids = @user.org.posts.ids
    assert_equal all_post_ids.sort, post_ids.sort

    [[:unblock, nil], [:block, flagged_post]].each do |action, blocked_post|
      flagged_post.send action

      get v1_posts_url, headers: @authorized_headers
      post_ids = get_post_ids_from_response

      assert_equal (all_post_ids - [blocked_post&.id]).sort, post_ids.sort
    end
  end

  test 'should show with valid authorization' do
    get v1_post_url(@post), headers: @authorized_headers
    assert_response :ok
    assert_pattern { response.parsed_body => post: { id: String } }
  end

  test 'should not show with invalid authorization' do
    get v1_post_url(@post),
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'show should only include ALLOWED_ATTRIBUTES' do
    get v1_post_url(@post), headers: @authorized_headers
    assert_pattern { response.parsed_body => { post:, **nil } }
    response.parsed_body => post:

    attribute_allow_list = Post::Query::ALLOWED_ATTRIBUTES.keys
    assert_equal attribute_allow_list.count, post.keys.count
    attribute_allow_list.each do |attribute|
      assert post.key? attribute
    end
  end

  test 'show response encrypted_body should be nil if it is not set' do
    assert_not @post.encrypted_body.blank?
    @post.update! encrypted_body: nil
    get v1_post_url(@post), headers: @authorized_headers
    assert_nil response.parsed_body.dig(:post, :encrypted_body)
  end

  test 'should not show post in another Org' do
    post_in_another_org = posts :two
    assert_not_equal @user.org, post_in_another_org.org
    get v1_post_url(post_in_another_org), headers: @authorized_headers
    assert_response :not_found
  end

  test 'should not show if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get v1_post_url(@post), headers: @authorized_headers
    assert_response :forbidden
  end

  test 'should not show for non-existent posts' do
    get v1_post_url('bad-post-id'), headers: @authorized_headers
    assert_response :not_found
  end

  private

  def get_post_ids_from_response
    response.parsed_body => posts: post_jsons
    post_jsons.map { |p| p[:id] }
  end
end
