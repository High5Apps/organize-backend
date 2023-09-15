require "test_helper"

class UpVoteTest < ActiveSupport::TestCase
  setup do
    @post_up_vote = up_votes(:one)
    @comment_up_vote = up_votes(:four)
  end

  test 'should be valid' do
    assert @post_up_vote.valid?
  end

  test 'value should be present' do
    @post_up_vote.value = nil
    assert @post_up_vote.invalid?
  end

  test 'value should be greater than or equal to -1' do
    @post_up_vote.value = -2
    assert @post_up_vote.invalid?
  end

  test 'value should be less than or equal to 1' do
    @post_up_vote.value = 2
    assert @post_up_vote.invalid?
  end

  test 'value should be an integer' do
    @post_up_vote.value = 0.5
    assert @post_up_vote.invalid?
  end

  test 'user should be present' do
    @post_up_vote.user = nil
    assert @post_up_vote.invalid?
  end

  test 'post should be optional' do
    @comment_up_vote.post = nil
    assert @comment_up_vote.valid?
  end

  test 'comment should be optional' do
    @post_up_vote.comment = nil
    assert @post_up_vote.valid?
  end

  test 'should allow a user to create multiple up votes on a single post' do
    assert_not_nil @post_up_vote.post
    assert_difference 'UpVote.count', 1 do
      @post_up_vote.dup.save
    end
  end

  test 'should allow users to create multiple up votes on a single comment' do
    assert_not_nil @comment_up_vote.comment
    assert_difference 'UpVote.count', 1 do
      @comment_up_vote.dup.save
    end
  end

  test 'should not allow both post and comment to be nil' do
    @post_up_vote.post = nil
    @post_up_vote.comment = nil
    assert @post_up_vote.invalid?
  end

  test 'should not allow both post and comment to be present' do
    @post_up_vote.comment = comments(:one)
    assert @post_up_vote.invalid?
  end

  test 'most_recent_created_before should not include newer post upvotes' do
    assert_not_equal 0, @post_up_vote.value

    time_now = UpVote.order(created_at: :desc).first.created_at + 1.second
    opposite_value = -1 * @post_up_vote.value

    assert_difference -> {
      UpVote.where(post: @post_up_vote.post).sum(:value)
    }, opposite_value do
      assert_no_difference -> {
        UpVote.most_recent_created_before(time_now)
          .where(post: @post_up_vote.post)
          .sum(:value)
      } do
        travel_to time_now + 1.second do
          uv = @post_up_vote.dup
          uv.value = -1 * @post_up_vote.value
          uv.save!
        end
      end
    end
  end

  test 'most_recent_created_before should not include newer comment upvotes' do
    assert_not_equal 0, @comment_up_vote.value

    time_now = UpVote.order(created_at: :desc).first.created_at + 1.second
    opposite_value = -1 * @comment_up_vote.value

    assert_difference -> {
      UpVote.where(comment: @comment_up_vote.comment).sum(:value)
    }, opposite_value do
      assert_no_difference -> {
        UpVote.most_recent_created_before(time_now)
          .where(comment: @comment_up_vote.comment)
          .sum(:value)
      } do
        travel_to time_now + 1.second do
          uv = @comment_up_vote.dup
          uv.value = -1 * @comment_up_vote.value
          uv.save!
        end
      end
    end
  end
end
