class PostQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)

    @post_with_upvotes = posts(:one)
    @post_without_upvotes = posts(:two)
    @another_post_without_upvotes = posts(:three)
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

  test 'sorting by new should be the opposite of sorting by old' do
    newest_posts = Post::Query.build({ sort: 'new' })
    oldest_posts = Post::Query.build({ sort: 'old' })
    assert_equal newest_posts, oldest_posts.reverse
  end

  test 'should order posts by most upvotes when sort param is top' do
    post_scores = Post::Query.build({ sort: 'top' }).map(&:score)

    # Reverse is needed because sort is an ascending sort
    assert_equal post_scores.sort.reverse, post_scores
  end

  test 'top sort should break ties by descending post ID' do
    assert_empty @post_without_upvotes.upvotes
    assert_empty @another_post_without_upvotes.upvotes
    alphabetically_sorted_post_ids = [
      @post_without_upvotes,
      @another_post_without_upvotes,
    ].map { |p| p.id }.sort
    expected_earlier_post = alphabetically_sorted_post_ids.last
    expected_later_post = alphabetically_sorted_post_ids.first

    post_ids = Post::Query.build({ sort: 'top' }).map(&:id)
    assert_operator post_ids.find_index(expected_earlier_post),
      :<,
      post_ids.find_index(expected_later_post)
  end

  test 'hot order should be stable over time when no new upvotes are created' do
    first_order = Post::Query.build({
      created_before: 1.year.from_now, sort: 'hot' }).ids
    second_order = Post::Query.build({
      created_before: 2.years.from_now, sort: 'hot' }).ids
    assert_not_empty first_order
    assert_equal first_order, second_order
  end

  test 'hot order should prefer newer posts with equal scores' do
    post_creator = @post_without_upvotes.user

    older_post = @post_without_upvotes.dup
    older_post.save!
    older_post.upvotes.create!(user: post_creator, value: 1)

    newer_post = @post_without_upvotes.dup
    newer_post.save!
    newer_post.upvotes.create!(user: post_creator, value: 1)

    post_ids = Post::Query.build({ created_before: Time.now, sort: 'hot' }).ids
    assert_operator post_ids.find_index(newer_post.id),
      :<, post_ids.find_index(older_post.id)
  end

  test 'hot order should prefer slightly older posts with higher scores' do
    post_creator = @post_without_upvotes.user

    older_post = @post_without_upvotes.dup
    older_post.save!
    older_post.upvotes.create!(user: post_creator, value: 1)

    # If this test fails after raising the gravity parameter, you probably need
    # to decrease this value.
    travel 1.hour

    newer_post = @post_without_upvotes.dup
    newer_post.save!

    travel 1.second
    newer_post.upvotes.create!(user: post_creator, value: 0)

    travel 1.second

    post_ids = Post::Query.build({ created_before: Time.now, sort: 'hot' }).ids
    assert_operator post_ids.find_index(older_post.id),
      :<, post_ids.find_index(newer_post.id)
  end

  test 'hot order should prefer much newer posts with slightly lower scores' do
    post_creator = @post_without_upvotes.user

    older_post = @post_without_upvotes.dup
    older_post.save!
    older_post.upvotes.create!(user: post_creator, value: 1)

    # If this test fails after lowering the gravity parameter, you probably need
    # to increase this value.
    travel 2.hours

    newer_post = @post_without_upvotes.dup
    newer_post.save!

    travel 1.second
    newer_post.upvotes.create!(user: post_creator, value: 0)

    travel 1.second

    post_ids = Post::Query.build({ created_before: Time.now, sort: 'hot' }).ids
    assert_operator post_ids.find_index(newer_post.id),
      :<, post_ids.find_index(older_post.id)
  end

  test 'hot order should prefer older posts with much higher scores' do
    post_creator = @post_without_upvotes.user

    older_post = @post_without_upvotes.dup
    older_post.save!
    older_post.upvotes.build(user: post_creator, value: 50)
      .save!(validate: false)

    # If this test fails after raising the gravity parameter, you probably need
    # to decrease this value.
    travel 1.day

    newer_post = @post_without_upvotes.dup
    newer_post.save!

    travel 1.second
    newer_post.upvotes.create!(user: post_creator, value: 0)

    travel 1.second

    post_ids = Post::Query.build({ created_before: Time.now, sort: 'hot' }).ids
    assert_operator post_ids.find_index(older_post.id),
      :<, post_ids.find_index(newer_post.id)
  end

  test 'hot order should prefer much newer posts with lower scores' do
    post_creator = @post_without_upvotes.user

    older_post = @post_without_upvotes.dup
    older_post.save!
    older_post.upvotes.build(user: post_creator, value: 50)
      .save!(validate: false)

    # If this test fails after lowering the gravity parameter, you probably need
    # to increase this value.
    travel 2.days

    newer_post = @post_without_upvotes.dup
    newer_post.save!

    travel 1.second
    newer_post.upvotes.create!(user: post_creator, value: 0)

    travel 1.second

    post_ids = Post::Query.build({ created_before: Time.now, sort: 'hot' }).ids
    assert_operator post_ids.find_index(newer_post.id),
      :<, post_ids.find_index(older_post.id)
  end

  test 'should only include allow-listed attributes' do
    posts = Post::Query.build({}, initial_posts: @user.org.posts)
    post_json = posts.first.as_json.with_indifferent_access
  
    attribute_allow_list = Post::Query::ALLOWED_ATTRIBUTES.keys

    attribute_allow_list.each do |attribute|
      assert post_json.key?(attribute)
    end

    assert_equal attribute_allow_list.count, post_json.keys.count
  end

  test 'should respect created_before param' do
    post = posts(:two)
    posts = Post::Query.build({ created_before: post.created_at })
    assert_not_equal Post.all.to_a.count, posts.to_a.count
    assert_equal Post.created_before(post.created_at).sort, posts.sort
  end

  test 'created_before should apply to upvotes' do
    upvote = upvotes(:three)
    post = upvote.post
    created_before = upvote.created_at

    windowed_posts = Post::Query.build({ created_before: created_before })
    windowed_score = windowed_posts.find(post.id).score
    unwindowed_score = Post::Query.build.find(post.id).score
    assert_not_equal unwindowed_score, windowed_score

    expected_score = Post.find(post.id).upvotes
      .filter{ |uv| uv.created_at < created_before }
      .map(&:value)
      .sum
    assert_equal expected_score, windowed_score
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

  test 'should include posts without any upvotes' do
    assert_empty @post_without_upvotes.upvotes
    post_ids = Post::Query.build.ids
    assert_includes post_ids, @post_without_upvotes.id
  end

  test 'posts without upvotes should have a score of 0' do
    post = Post::Query.build.find @post_without_upvotes.id
    assert_equal 0, post.score
  end

  test 'should include score as the sum of upvote and downvotes' do
    assert_not_empty @post_with_upvotes.upvotes
    expected_score = @post_with_upvotes.upvotes.sum(:value)
    post = Post::Query.build.find @post_with_upvotes.id
    assert_equal expected_score, post.score
  end

  test "should include my_vote as the requester's upvote value" do
    expected_vote = @user.upvotes.where(post: @post_with_upvotes).first.value
    assert_not_equal 0, expected_vote
    vote = Post::Query.build({ requester_id: @user.id})
      .find(@post_with_upvotes.id).my_vote
    assert_equal expected_vote, vote
  end

  test 'should include my_vote as 0 when the user has not upvoted or downvoted' do
    vote = Post::Query.build({ requester_id: @user.id})
      .find(@post_without_upvotes.id).my_vote
    assert_equal 0, vote
  end
end
