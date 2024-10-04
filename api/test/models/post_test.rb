require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @post = posts(:one)
    @candidacy_announcement = posts(:candidacy_announcement)
  end

  test 'should be valid' do
    assert @post.valid?
    assert @candidacy_announcement.valid?
  end

  test 'org should be present' do
    @post.org = nil
    assert @post.invalid?
  end

  test 'org should be user org' do
    @post.org_id = 'bad-id'
    assert_not_equal @post.user.org_id, @post.org_id
    assert @post.invalid?
  end

  test 'candidacy announcement should not be created once voting ends' do
    post = @candidacy_announcement.dup
    @candidacy_announcement.destroy!

    travel_to post.candidate.ballot.voting_ends_at do
      assert_not post.save
    end

    travel_to post.candidate.ballot.voting_ends_at - 1.second do
      assert post.save
    end
  end

  test 'candidacy announcement should only be created by candidate' do
    @candidacy_announcement.user = users :three
    assert @candidacy_announcement.invalid?
  end

  test 'category should be present' do
    @post.category = nil
    assert @post.invalid?
  end

  test 'category should be general for candidacy announcements' do
    @candidacy_announcement.category = :grievances
    assert @candidacy_announcement.invalid?
  end

  test 'encrypted_title should be present' do
    @post.encrypted_title = nil
    assert @post.invalid?
  end

  test 'encrypted_title error messages should not include "Encrypted"' do
    @post.encrypted_title = nil
    @post.valid?
    assert_not @post.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_title should be no longer than MAX_TITLE_LENGTH' do
    @post.encrypted_title.ciphertext = \
      Base64.strict_encode64('a' * Post::MAX_TITLE_LENGTH)
    assert @post.valid?

    @post.encrypted_title.ciphertext = \
      Base64.strict_encode64('a' * (1 + Post::MAX_TITLE_LENGTH))
    assert @post.invalid?
  end

  # Note that this is the only test of this functionality from the Encryptable
  # module. Do not remove this test without first testing it on another
  # Encryptable.
  test 'invalid encrypted_title should cause post to be invalid' do
    @post.encrypted_title.auth_tag = 'bad'
    assert @post.encrypted_title.invalid?
    assert @post.invalid?
  end

  test 'encrypted_attributes should include expected attributes' do
    assert_equal ['encrypted_body', 'encrypted_title'],
      Post.encrypted_attributes.sort
  end

  test 'encrypted_body should be optional' do
    @post.encrypted_body = nil
    assert @post.valid?
  end

  test 'encrypted_body should be nil when not present' do
    @post.update! encrypted_body: nil
    assert_nil @post.encrypted_body_before_type_cast
  end

  test 'encrypted_body should be no longer than MAX_BODY_LENGTH' do
    @post.encrypted_body.ciphertext = \
      Base64.strict_encode64('a' * Post::MAX_BODY_LENGTH)
    assert @post.valid?

    @post.encrypted_body.ciphertext = \
      Base64.strict_encode64('a' * (1 + Post::MAX_BODY_LENGTH))
    assert @post.invalid?
  end

  test 'encrypted_body error messages should not include "Encrypted"' do
    @post.encrypted_body.ciphertext = \
      Base64.strict_encode64('a' * (1 + Post::MAX_BODY_LENGTH))
    @post.valid?
    assert_not @post.errors.full_messages.first.include? 'Encrypted'
  end

  test 'user should be present' do
    @post.user = nil
    assert @post.invalid?
  end

  test 'user should be in an Org' do
    user_without_org = users :two
    assert_nil user_without_org.org
    @post.user = user_without_org
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

  test 'created_at_or_before should filter by created_at' do
    post = posts(:two)
    created_at = post.created_at
    posts = Post.created_at_or_before(created_at)
    assert_not_equal Post.count, posts.count
    assert_not_empty posts
    assert posts.all? { |post| post.created_at <= created_at }
  end
end
