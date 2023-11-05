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

  test 'encrypted_title should be no longer than MAX_TITLE_LENGTH' do
    @post.encrypted_title.ciphertext = \
      Base64.strict_encode64('a' * Post::MAX_TITLE_LENGTH)
    assert @post.valid?

    @post.encrypted_title.ciphertext = \
      Base64.strict_encode64('a' * (1 + Post::MAX_TITLE_LENGTH))
    assert @post.invalid?
  end

  test 'encrypted_body should be optional' do
    @post.encrypted_body = nil
    assert @post.valid?
  end

  test 'encrypted_body should be no longer than MAX_BODY_LENGTH' do
    @post.encrypted_body.ciphertext = \
      Base64.strict_encode64('a' * Post::MAX_BODY_LENGTH)
    assert @post.valid?

    @post.encrypted_body.ciphertext = \
      Base64.strict_encode64('a' * (1 + Post::MAX_BODY_LENGTH))
    assert @post.invalid?
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

    assert_not new_post.general?
    assert_no_difference '@post.user.upvotes.count' do
      new_post.general!
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
