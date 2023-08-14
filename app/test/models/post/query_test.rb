class PostQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test 'should respect initial_posts' do
    org = @user.org
    assert Post.where.not(org: org)
    post_ids = Post::Query.build({}, initial_posts: org.posts).ids
    posts = Post.find(post_ids)
    assert posts.all? { |post| post.org == org }
  end

  test 'should order posts with newest first by default' do
    post_created_ats = Post::Query.build({}).pluck :created_at

    # Reverse is needed because sort is an ascending sort
    assert_equal post_created_ats.sort.reverse, post_created_ats
  end

  test 'should order posts with newest first when sort param is new' do
    post_created_ats = Post::Query.build({ sort: 'new' }).pluck :created_at

    # Reverse is needed because sort is an ascending sort
    assert_equal post_created_ats.sort.reverse, post_created_ats
  end

  test 'should order posts with oldest first when sort param is old' do
    post_created_ats = Post::Query.build({ sort: 'old' }).pluck :created_at
    assert_equal post_created_ats.sort, post_created_ats
  end

  test 'should only include allow-listed attributes' do
    posts = Post::Query.build({}, initial_posts: @user.org.posts)
    post_json = posts.first.as_json.with_indifferent_access
  
    attribute_allow_list = Post::Query::ATTRIBUTE_ALLOW_LIST

    attribute_allow_list.each do |attribute|
      assert post_json.key?(attribute)
    end

    assert_equal attribute_allow_list.count, post_json.keys.count
  end

  test 'should respect created_after param' do
    post = posts(:one)
    posts = Post::Query.build({ created_after: post.created_at })
    assert_not_equal Post.all, posts
    assert_equal Post.created_after(post.created_at).sort, posts.sort
  end
end
