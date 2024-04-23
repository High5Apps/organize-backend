class FlaggedItem < ApplicationRecord
  belongs_to :ballot, optional: true
  belongs_to :comment, optional: true
  belongs_to :post, optional: true
  belongs_to :user

  validates :user, presence: true

  validate :exactly_one_item

  private

  def exactly_one_item
    item_count = item_ids.compact.count
    unless item_count == 1
      errors.add :base, "must have exactly one item, not #{item_count}"
    end
  end

  def item_ids
    [ballot_id, comment_id, post_id]
  end
end
