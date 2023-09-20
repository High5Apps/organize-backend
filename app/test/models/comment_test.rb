require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @comment = comments(:one)
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
end
