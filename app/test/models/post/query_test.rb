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
    post = posts(:two)
    posts = Post::Query.build({ created_after: post.created_at })
    assert_not_equal Post.all, posts
    assert_equal Post.created_after(post.created_at).sort, posts.sort
  end

  test 'should respect created_before param' do
    post = posts(:two)
    posts = Post::Query.build({ created_before: post.created_at })
    assert_not_equal Post.all, posts
    assert_equal Post.created_before(post.created_at).sort, posts.sort
  end

  test 'should include all categories when category param is not set' do
    posts = Post::Query.build.to_a
    assert posts.any?(&:general?)
    assert posts.any?(&:grievances?)
    assert posts.any?(&:demands?)
  end

  test 'should only include general posts when category param is general' do
    posts = Post::Query.build({ category: 'general'})
    assert posts.to_a.all?(&:general?)
  end

  test 'should only include grievances when category param is grievances' do
    posts = Post::Query.build({ category: 'grievances'})
    assert posts.to_a.all?(&:grievances?)
  end

  test 'should only include demands when category param is demands' do
    posts = Post::Query.build({ category: 'demands'})
    assert posts.to_a.all?(&:demands?)
  end
end
