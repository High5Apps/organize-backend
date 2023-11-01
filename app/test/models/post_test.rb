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

  test 'encrypted_title should be present' do
    @post.encrypted_title = nil
    assert @post.invalid?
  end

  test 'encrypted_title should be less than MAX_TITLE_LENGTH' do
    @post.encrypted_title.c = \
      Base64.strict_encode64('a' * Post::MAX_TITLE_LENGTH)
    assert @post.valid?

    @post.encrypted_title.c = \
      Base64.strict_encode64('a' * (1 + Post::MAX_TITLE_LENGTH))
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

  test 'title should automatically be stripped of whitespace' do
    expected_content = 'a b c'
    @post.title = "\n\n\t\r #{expected_content} \n\t\r"
    assert @post.valid?
    assert_equal expected_content, @post.title
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

  test 'body should automatically be stripped of whitespace' do
    expected_content = 'a b c'
    @post.body = "\n\n\t\r #{expected_content} \n\t\r"
    assert @post.valid?
    assert_equal expected_content, @post.body
  end

  test 'user should be present' do
    @post.user = nil
    assert @post.invalid?
  end

  test 'should auto-upvote on successful creation' do
    assert_difference '@post.user.upvotes.count', 1 do
      @post.dup.save!
    end
  end

  test 'should not auto-upvote on update' do
    new_post = @post.dup
    new_post.save!

    assert_no_difference '@post.user.upvotes.count' do
      new_post.update! title: 'new title'
    end
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
