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

  test 'index should include score as the sum of upvotes and downvotes' do
    assert_not_empty @comment_with_upvotes.upvotes

    get api_v1_post_comments_url(@comment_with_upvotes.post),
      headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    comment_jsons = json_response.dig(:comments)
    comment = comment_jsons.find { |c| c[:id] == @comment_with_upvotes.id }

    expected_score = @comment_with_upvotes.upvotes.sum(:value)
    assert_equal expected_score, comment[:score]
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

  test 'index sort should be stable over time when no new upvotes are created' do
    assert_not_empty @post.comments
    assert_not_empty @post.comments.first.upvotes

    get api_v1_post_comments_url(@post),
      headers: @authorized_headers,
      params: { created_before: Time.now.to_f }
    first_comment_ids = JSON.parse(response.body, symbolize_names: true)
      .dig(:comments)
      .map {|comment| comment[:id]}

    get api_v1_post_comments_url(@post),
      headers: @authorized_headers,
      params: { created_before: 1.year.from_now.to_f }
    second_comment_ids = JSON.parse(response.body, symbolize_names: true)
      .dig(:comments)
      .map {|comment| comment[:id]}

    assert_not_empty first_comment_ids
    assert_equal first_comment_ids, second_comment_ids
  end

  test 'index sort should prefer newer comments with equal scores' do
    assert_empty @post_without_comments.comments
    post_creator = @post_without_comments.user

    older_comment = \
      @post_without_comments.comments.create!(body: 'body', user: post_creator)
    older_comment.upvotes.create!(user: post_creator, value: 1)

    newer_comment = older_comment.dup
    newer_comment.save!
    newer_comment.upvotes.create!(user: post_creator, value: 1)

    get api_v1_post_comments_url(@post_without_comments),
      headers: @authorized_headers,
      params: { created_before: Time.now.to_f }
    comment_ids = JSON.parse(response.body, symbolize_names: true)
      .dig(:comments)
      .map {|comment| comment[:id]}
    assert_operator comment_ids.find_index(newer_comment.id),
      :<, comment_ids.find_index(older_comment.id)
  end

  test 'index sort should prefer slightly older comments with higher scores' do
    post_creator = @post_without_comments.user

    older_comment = \
      @post_without_comments.comments.create!(body: 'body', user: post_creator)
    older_comment.upvotes.create!(user: post_creator, value: 1)

    # If this test fails after raising the gravity parameter, you probably need
    # to decrease this value.
    travel 1.hour

    newer_comment = older_comment.dup
    newer_comment.save!

    travel 1.second

    get api_v1_post_comments_url(@post_without_comments),
      headers: authorized_headers(@user, '*'),
      params: { created_before: Time.now.to_f }
    comment_ids = JSON.parse(response.body, symbolize_names: true)
      .dig(:comments)
      .map {|comment| comment[:id]}
    assert_operator comment_ids.find_index(older_comment.id),
      :<, comment_ids.find_index(newer_comment.id)
  end

  test 'index sort should prefer much newer comments with slightly lower scores' do
    post_creator = @post_without_comments.user

    older_comment = \
      @post_without_comments.comments.create!(body: 'body', user: post_creator)
    older_comment.upvotes.create!(user: post_creator, value: 1)

    # If this test fails after lowering the gravity parameter, you probably need
    # to increase this value.
    travel 2.hours

    newer_comment = older_comment.dup
    newer_comment.save!

    travel 1.second

    get api_v1_post_comments_url(@post_without_comments),
      headers: authorized_headers(@user, '*'),
      params: { created_before: Time.now.to_f }
    comment_ids = JSON.parse(response.body, symbolize_names: true)
      .dig(:comments)
      .map {|comment| comment[:id]}
    assert_operator comment_ids.find_index(newer_comment.id),
      :<, comment_ids.find_index(older_comment.id)
  end

  test 'index sort should prefer older comments with much higher scores' do
    post_creator = @post_without_comments.user

    older_comment = \
      @post_without_comments.comments.create!(body: 'body', user: post_creator)
    older_comment.upvotes.build(user: post_creator, value: 50)
      .save!(validate: false)

    # If this test fails after raising the gravity parameter, you probably need
    # to decrease this value.
    travel 1.day

    newer_comment = older_comment.dup
    newer_comment.save!

    travel 1.second

    get api_v1_post_comments_url(@post_without_comments),
      headers: authorized_headers(@user, '*'),
      params: { created_before: Time.now.to_f }
    comment_ids = JSON.parse(response.body, symbolize_names: true)
      .dig(:comments)
      .map {|comment| comment[:id]}
    assert_operator comment_ids.find_index(older_comment.id),
      :<, comment_ids.find_index(newer_comment.id)
  end

  test 'index sort should prefer much newer comments with lower scores' do
    post_creator = @post_without_comments.user

    older_comment = \
      @post_without_comments.comments.create!(body: 'body', user: post_creator)
    older_comment.upvotes.build(user: post_creator, value: 50)
      .save!(validate: false)

    # If this test fails after lowering the gravity parameter, you probably need
    # to increase this value.
    travel 2.days

    newer_comment = older_comment.dup
    newer_comment.save!

    travel 1.second

    get api_v1_post_comments_url(@post_without_comments),
      headers: authorized_headers(@user, '*'),
      params: { created_before: Time.now.to_f }
    comment_ids = JSON.parse(response.body, symbolize_names: true)
      .dig(:comments)
      .map {|comment| comment[:id]}
    assert_operator comment_ids.find_index(newer_comment.id),
      :<, comment_ids.find_index(older_comment.id)
  end
end
