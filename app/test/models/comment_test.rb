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
end