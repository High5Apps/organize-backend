require "test_helper"

class UpvoteTest < ActiveSupport::TestCase
  setup do
    @post_upvote = upvotes(:one)
    @comment_upvote = upvotes(:four)
  end

  test 'should be valid' do
    assert @post_upvote.valid?
  end

  test 'value should be present' do
    @post_upvote.value = nil
    assert @post_upvote.invalid?
  end

  test 'value should be greater than or equal to -1' do
    @post_upvote.value = -2
    assert @post_upvote.invalid?
  end

  test 'value should be less than or equal to 1' do
    @post_upvote.value = 2
    assert @post_upvote.invalid?
  end

  test 'value should be an integer' do
    @post_upvote.value = 0.5
    assert @post_upvote.invalid?
  end

  test 'user should be present' do
    @post_upvote.user = nil
    assert @post_upvote.invalid?
  end

  test 'post should be optional' do
    @comment_upvote.post = nil
    assert @comment_upvote.valid?
  end

  test 'post should exist if given' do
    @post_upvote.post_id = 'bad-id'
    assert @post_upvote.invalid?
  end

  test 'post should belong to user Org if given' do
    post_in_another_org = posts :two
    assert_not_equal post_in_another_org.org, @post_upvote.user.org
    @post_upvote.post = post_in_another_org
    assert @post_upvote.invalid?
  end

  test 'comment should be optional' do
    @post_upvote.comment = nil
    assert @post_upvote.valid?
  end

  test 'comment should exist if given' do
    @comment_upvote.comment_id = 'bad-id'
    assert @comment_upvote.invalid?
  end

  test 'comment should belong to user Org if given' do
    comment_in_another_org = comments :three
    assert_not_equal comment_in_another_org.user.org, @comment_upvote.user.org
    @comment_upvote.comment = comment_in_another_org
    assert @comment_upvote.invalid?
  end

  test 'should not allow users to double upvote the same post' do
    assert_not_nil @post_upvote.post
    assert_no_difference 'Upvote.count' do
      assert_raises do
        @post_upvote.dup.save
      end
    end
  end

  test 'should not allow users to double upvote the same comment' do
    assert_not_nil @comment_upvote.comment
    assert_no_difference 'Upvote.count' do
      assert_raises do
        @comment_upvote.dup.save
      end
    end
  end

  test 'should not allow both post and comment to be nil' do
    @post_upvote.post = nil
    @post_upvote.comment = nil
    assert @post_upvote.invalid?
  end

  test 'should not allow both post and comment to be present' do
    @post_upvote.comment = comments(:one)
    assert @post_upvote.invalid?
  end
end
