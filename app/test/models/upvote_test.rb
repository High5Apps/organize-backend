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

  test 'comment should be optional' do
    @post_upvote.comment = nil
    assert @post_upvote.valid?
  end

  test 'should allow a user to create multiple up votes on a single post' do
    assert_not_nil @post_upvote.post
    assert_difference 'Upvote.count', 1 do
      @post_upvote.dup.save
    end
  end

  test 'should allow users to create multiple up votes on a single comment' do
    assert_not_nil @comment_upvote.comment
    assert_difference 'Upvote.count', 1 do
      @comment_upvote.dup.save
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

  test 'most_recent_created_before should not include newer post upvotes' do
    assert_not_equal 0, @post_upvote.value

    time_now = Upvote.order(created_at: :desc).first.created_at + 1.second
    opposite_value = -1 * @post_upvote.value

    assert_difference -> {
      Upvote.where(post: @post_upvote.post).sum(:value)
    }, opposite_value do
      assert_no_difference -> {
        Upvote.most_recent_created_before(time_now)
          .where(post: @post_upvote.post)
          .sum(:value)
      } do
        travel_to time_now + 1.second do
          uv = @post_upvote.dup
          uv.value = -1 * @post_upvote.value
          uv.save!
        end
      end
    end
  end

  test 'most_recent_created_before should not include newer comment upvotes' do
    assert_not_equal 0, @comment_upvote.value

    time_now = Upvote.order(created_at: :desc).first.created_at + 1.second
    opposite_value = -1 * @comment_upvote.value

    assert_difference -> {
      Upvote.where(comment: @comment_upvote.comment).sum(:value)
    }, opposite_value do
      assert_no_difference -> {
        Upvote.most_recent_created_before(time_now)
          .where(comment: @comment_upvote.comment)
          .sum(:value)
      } do
        travel_to time_now + 1.second do
          uv = @comment_upvote.dup
          uv.value = -1 * @comment_upvote.value
          uv.save!
        end
      end
    end
  end
end
