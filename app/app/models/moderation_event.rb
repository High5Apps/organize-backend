class ModerationEvent < ApplicationRecord
  enum :action, [:allow, :block, :undo_allow, :undo_block], validate: true

  belongs_to :ballot, optional: true
  belongs_to :comment, optional: true
  belongs_to :post, optional: true
  belongs_to :moderator, class_name: 'User'
  belongs_to :user, optional: true

  validates :moderator, presence: true
  validate :exactly_one_item

  private

  def exactly_one_item
    item_count = item_ids.compact.count
    unless item_count == 1
      errors.add :base, "must have exactly one item, not #{item_count}"
    end
  end

  def item_ids
    [ballot_id, comment_id, post_id, user_id]
  end
end
