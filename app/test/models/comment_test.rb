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

  test 'encrypted_body should be present' do
    @comment.encrypted_body = nil
    assert @comment.invalid?
  end

  test 'encrypted_body error messages should not include "Encrypted"' do
    @comment.encrypted_body = nil
    @comment.valid?
    assert_not @comment.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_body should be less than MAX_BODY_LENGTH' do
    @comment.encrypted_body.ciphertext = \
      Base64.strict_encode64('a' * Comment::MAX_BODY_LENGTH)
    assert @comment.valid?
    @comment.encrypted_body.ciphertext = \
      Base64.strict_encode64('a' * (1 + Comment::MAX_BODY_LENGTH))
    assert @comment.invalid?
  end

  test 'comments should have a maximum depth of MAX_COMMENT_DEPTH' do
    comment = @comment.dup
    assert comment.save!
    assert_equal 0, comment.depth

    (1...Comment::MAX_COMMENT_DEPTH).each do
      comment = comment.children.build(
        encrypted_body: @comment.encrypted_body,
        post: @comment.post,
        user: @comment.user)
      assert comment.save!
    end

    comment = comment.children.build(
      post: @comment.post,
      user: @comment.user)
    assert_not comment.save
  end

  test 'should auto-upvote on successful creation' do
    assert_difference '@comment.user.upvotes.count', 1 do
      @comment.dup.save!
    end
  end

  test 'should not auto-upvote on update' do
    new_comment = @comment.dup
    new_comment.save!

    new_depth = 5
    assert_not_equal new_depth, new_comment.depth
    assert_no_difference '@comment.user.upvotes.count' do
      new_comment.update! depth: new_depth
    end
  end

  test 'created_at_or_before should filter by created_at' do
    comment = comments(:two)
    created_at = comment.created_at
    comments = Comment.created_at_or_before(created_at)
    assert_not_equal Comment.count, comments.count
    assert_not_empty comments
    assert comments.all? { |comment| comment.created_at <= created_at }
  end

  test 'includes_pseudonym should include pseudonyms' do
    pseudonyms = Comment.includes_pseudonym.map(&:pseudonym)
    assert_not_empty pseudonyms
    pseudonyms.each { |p| assert_not_empty p }
  end

  test 'includes_score_from_upvotes_created_at_or_before should include score as the sum of upvotes and downvotes' do
    assert_not_empty @comment.upvotes

    expected_score = @comment.upvotes.sum(:value)
    comment_with_score = Comment
      .includes_score_from_upvotes_created_at_or_before(Time.now)
      .find(@comment.id)
    assert_equal expected_score, comment_with_score.score
  end

  test "includes_my_vote_from_upvotes_created_at_or_before should include my_vote as the requester's upvote value" do
    user = @comment.upvotes.first.user
    expected_vote = user.upvotes
      .where(comment: @comment).first.value
    assert_not_equal 0, expected_vote

    my_vote = Comment
      .includes_my_vote_from_upvotes_created_at_or_before(Time.now, user.id)
      .find(@comment.id).my_vote
    assert_equal expected_vote, my_vote
  end

  test 'includes_my_vote_from_upvotes_created_at_or_before should include my_vote as 0 when the user has not upvoted or downvoted' do
    comment_without_upvotes = comments(:two)
    user = comment_without_upvotes.user
    assert_empty comment_without_upvotes.upvotes

    my_vote = Comment
      .includes_my_vote_from_upvotes_created_at_or_before(Time.now, user.id)
      .find(comment_without_upvotes.id).my_vote
    assert_equal 0, my_vote
  end

  test 'order_by_hot_created_at_or_before should be stable over time when no new upvotes are created' do
    assert_not_empty @post.comments
    assert_not_empty @post.comments.first.upvotes

    first_comment_ids = @post.comments
      .order_by_hot_created_at_or_before(Time.now).pluck(:id)
    second_comment_ids = @post.comments
      .order_by_hot_created_at_or_before(1.year.from_now).pluck(:id)

    assert_not_empty first_comment_ids
    assert_equal first_comment_ids, second_comment_ids
  end

  test 'order_by_hot_created_at_or_before should prefer newer comments with equal scores' do
    older_comment, newer_comment = create_comments(
      older_time: 2.seconds.ago, older_score: 1,
      newer_time: 1.second.ago, newer_score: 1)
    assert_ordered higher: newer_comment, lower: older_comment
  end

  test 'order_by_hot_created_at_or_before should prefer slightly older comments with higher scores' do
    # If this test fails after raising the gravity parameter, you probably need
    # to make older_time newer
    older_comment, newer_comment = create_comments(
      older_time: 1.hour.ago, older_score: 2,
      newer_time: 1.second.ago, newer_score: 1)
    assert_ordered higher: older_comment, lower: newer_comment
  end

  test 'order_by_hot_created_at_or_before should prefer much newer comments with slightly lower scores' do
    # If this test fails after lowering the gravity parameter, you probably need
    # to make older_time older
    older_comment, newer_comment = create_comments(
      older_time: 2.hours.ago, older_score: 2,
      newer_time: 1.second.ago, newer_score: 1)
    assert_ordered higher: newer_comment, lower: older_comment
  end

  test 'order_by_hot_created_at_or_before should prefer older comments with much higher scores' do
    # If this test fails after raising the gravity parameter, you probably need
    # to increase older_score
    older_comment, newer_comment = create_comments(
      older_time: 24.hours.ago, older_score: 24,
      newer_time: 1.second.ago, newer_score: 1)
    assert_ordered higher: older_comment, lower: newer_comment
  end

  test 'order_by_hot_created_at_or_before should prefer much newer comments with lower scores' do
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
    encrypted_body = @comment.encrypted_body

    travel_to older_time - 1.second do
      older_comment = @post_without_comments.comments
        .create!(encrypted_body:, user: post_creator)

      travel 1.second
      older_comment.upvotes.build(user: post_creator, value: older_score)
        .save!(validate: false)
    end

    travel_to newer_time - 1.second do
      newer_comment = @post_without_comments.comments
        .create!(encrypted_body:, user: post_creator)

      travel 1.second
      newer_comment.upvotes.build(user: post_creator, value: newer_score)
        .save!(validate: false)
    end

    return older_comment, newer_comment
  end

  def assert_ordered(higher:, lower:)
    comment_ids = @post_without_comments.comments
      .order_by_hot_created_at_or_before(Time.now).pluck(:id)
    assert_operator comment_ids.find_index(higher.id),
      :<, comment_ids.find_index(lower.id)
  end
end
