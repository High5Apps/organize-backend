require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @comment = comments(:one)
    @post = posts(:one)
    @post_without_comments = posts(:three)
  end

  test 'should be valid' do
    assert @comment.valid?
  end

  test 'post should be present' do
    @comment.post = nil
    assert @comment.invalid?
  end

  test 'user should be present' do
    @comment.user = nil
    assert @comment.invalid?
  end

  test 'body should be present' do
    @comment.body = nil
    assert @comment.invalid?
  end

  test 'body should not be empty' do
    @comment.body = '       '
    assert @comment.invalid?
  end

  test 'body should not be longer than MAX_BODY_LENGTH' do
    @comment.body = 'a' * Comment::MAX_BODY_LENGTH
    assert @comment.valid?

    @comment.body = 'a' * (1 + Comment::MAX_BODY_LENGTH)
    assert @comment.invalid?
  end

  test 'created_before should filter by created_at' do
    comment = comments(:two)
    created_at = comment.created_at
    comments = Comment.created_before(created_at)
    assert_not_equal Comment.count, comments.count
    assert_not_empty comments
    assert comments.all? { |comment| comment.created_at < created_at }
  end

  test 'includes_pseudonym should include pseudonyms' do
    pseudonyms = Comment.includes_pseudonym.map(&:pseudonym)
    assert_not_empty pseudonyms
    pseudonyms.each { |p| assert_not_empty p } 
  end

  test 'order_by_hot_created_before should be stable over time when no new upvotes are created' do
    assert_not_empty @post.comments
    assert_not_empty @post.comments.first.upvotes

    first_comment_ids = \
      @post.comments.order_by_hot_created_before(Time.now).pluck(:id)
    second_comment_ids = \
      @post.comments.order_by_hot_created_before(1.year.from_now).pluck(:id)

    assert_not_empty first_comment_ids
    assert_equal first_comment_ids, second_comment_ids
  end

  test 'order_by_hot_created_before should prefer newer comments with equal scores' do
    older_comment, newer_comment = create_comments(
      older_time: 2.seconds.ago, older_score: 1,
      newer_time: 1.second.ago, newer_score: 1)
    assert_ordered higher: newer_comment, lower: older_comment
  end

  test 'order_by_hot_created_before should prefer slightly older comments with higher scores' do
    # If this test fails after raising the gravity parameter, you probably need
    # to make older_time newer
    older_comment, newer_comment = create_comments(
      older_time: 1.hour.ago, older_score: 2,
      newer_time: 1.second.ago, newer_score: 1)
    assert_ordered higher: older_comment, lower: newer_comment
  end

  test 'order_by_hot_created_before should prefer much newer comments with slightly lower scores' do
    # If this test fails after lowering the gravity parameter, you probably need
    # to make older_time older
    older_comment, newer_comment = create_comments(
      older_time: 2.hours.ago, older_score: 2,
      newer_time: 1.second.ago, newer_score: 1)
    assert_ordered higher: newer_comment, lower: older_comment
  end

  test 'order_by_hot_created_before should prefer older comments with much higher scores' do
    # If this test fails after raising the gravity parameter, you probably need
    # to increase older_score
    older_comment, newer_comment = create_comments(
      older_time: 24.hours.ago, older_score: 24,
      newer_time: 1.second.ago, newer_score: 1)
    assert_ordered higher: older_comment, lower: newer_comment
  end

  test 'order_by_hot_created_before should prefer much newer comments with lower scores' do
    # If this test fails after lowering the gravity parameter, you probably need
    # to make older_time older
    older_comment, newer_comment = create_comments(
      older_time: 48.hours.ago, older_score: 24,
      newer_time: 1.second.ago, newer_score: 1)
    assert_ordered higher: newer_comment, lower: older_comment
  end

  private

  def create_comments(older_time:, older_score:, newer_time:, newer_score:)
    older_comment, newer_comment = nil
    post_creator = @post_without_comments.user

    travel_to older_time do
      older_comment = @post_without_comments.comments
        .create!(body: 'body', user: post_creator)
      older_comment.upvotes.build(user: post_creator, value: older_score)
        .save!(validate: false)
    end

    travel_to newer_time do
      newer_comment = @post_without_comments.comments
        .create!(body: 'body', user: post_creator)
      newer_comment.upvotes.build(user: post_creator, value: newer_score)
        .save!(validate: false)
    end

    return older_comment, newer_comment
  end

  def assert_ordered(higher:, lower:)
    comment_ids = @post_without_comments.comments
      .order_by_hot_created_before(Time.now).pluck(:id)
    assert_operator comment_ids.find_index(higher.id),
      :<, comment_ids.find_index(lower.id)
  end
end
