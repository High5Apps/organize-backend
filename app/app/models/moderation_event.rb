class ModerationEvent < ApplicationRecord
  enum :action, [:allow, :block, :undo_allow, :undo_block], validate: true

  belongs_to :ballot, optional: true
  belongs_to :comment, optional: true
  belongs_to :post, optional: true
  belongs_to :moderator, class_name: 'User'
  belongs_to :user, optional: true

  validates :moderator, presence: true
  validate :exactly_one_item

  def item
    non_nil_items = item_ids.compact
    return nil unless non_nil_items.count == 1

    case non_nil_items.first
    when ballot_id
      ballot
    when comment_id
      comment
    when post_id
      post
    when user_id
      user
    end
  end

  def item=(updated_item)
    self.ballot_id = nil
    self.comment_id = nil
    self.post_id = nil
    self.user_id = nil

    case updated_item.class.name
    when 'Ballot'
      self.ballot_id = updated_item.id
    when 'Comment'
      self.comment_id = updated_item.id
    when 'Post'
      self.post_id = updated_item.id
    when 'User'
      self.user_id = updated_item.id
    else
      raise 'unexpected item class'
    end
  end

  private

  def exactly_one_item
    unless item
      errors.add :base, 'must have exactly one item'
    end
  end

  def item_ids
    [ballot_id, comment_id, post_id, user_id]
  end
end
