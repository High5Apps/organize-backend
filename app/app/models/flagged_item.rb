class FlaggedItem < ApplicationRecord
  scope :created_at_or_before, ->(time) { where(created_at: ..time) }

  belongs_to :ballot, optional: true
  belongs_to :comment, optional: true
  belongs_to :post, optional: true
  belongs_to :user

  validates :user, presence: true

  validate :ballot_category_is_not_election
  validate :exactly_one_item
  validate :post_is_not_candidacy_announcement

  private

  def ballot_category_is_not_election
    return unless ballot_id

    if ballot.election?
      errors.add :base, "Elections can't be flagged"
    end
  end

  def exactly_one_item
    item_count = item_ids.compact.count
    unless item_count == 1
      errors.add :base, "must have exactly one item, not #{item_count}"
    end
  end

  def item_ids
    [ballot_id, comment_id, post_id]
  end

  def post_is_not_candidacy_announcement
    return unless post_id

    if post.candidate_id
      errors.add :base, "Candidacy announcements can't be flagged"
    end
  end
end
