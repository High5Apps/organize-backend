require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @post = posts(:one)
  end

  test 'should be valid' do
    assert @post.valid?
  end

  test 'org should be present' do
    @post.org = nil
    assert @post.invalid?
  end

  test 'category should be present' do
    @post.category = nil
    assert @post.invalid?
  end

  test 'title should be present' do
    @post.title = ' '
    assert @post.invalid?
  end

  test 'title should not be longer than MAX_TITLE_LENGTH' do
    @post.title = 'a' * Post::MAX_TITLE_LENGTH
    assert @post.valid?

    @post.title = 'a' * (1 + Post::MAX_TITLE_LENGTH)
    assert @post.invalid?
  end

  test 'body should be optional' do
    @post.body = nil
    assert @post.valid?
  end

  test 'body should not be longer than MAX_BODY_LENGTH' do
    @post.body = 'a' * Post::MAX_BODY_LENGTH
    assert @post.valid?

    @post.body = 'a' * (1 + Post::MAX_BODY_LENGTH)
    assert @post.invalid?
  end

  test 'user should be present' do
    @post.user = nil
    assert @post.invalid?
  end

  test 'created_after should filter by created_at' do
    post = posts(:two)
    created_at = post.created_at
    posts = Post.created_after(created_at)
    assert_not_equal Post.count, posts.count
    assert_not_empty posts
    assert posts.all? { |post| post.created_at > created_at }
  end

  test 'created_before should filter by created_at' do
    post = posts(:two)
    created_at = post.created_at
    posts = Post.created_before(created_at)
    assert_not_equal Post.count, posts.count
    assert_not_empty posts
    assert posts.all? { |post| post.created_at < created_at }
  end
end
