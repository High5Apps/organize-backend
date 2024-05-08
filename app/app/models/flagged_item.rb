class FlaggedItem < ApplicationRecord
  scope :created_at_or_before, ->(time) { where(created_at: ..time) }

  belongs_to :ballot, optional: true
  belongs_to :comment, optional: true
  belongs_to :post, optional: true
  belongs_to :user

  validates :user,
    presence: true,
    same_org: {
      as: ->(flagged_item) { flagged_item.item&.user },
      name: 'Item',
    }

  validate :ballot_category_is_not_election
  validate :exactly_one_item
  validate :post_is_not_candidacy_announcement

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
    end
  end

  def item=(updated_item)
    self.ballot_id = nil
    self.comment_id = nil
    self.post_id = nil

    case updated_item.class.name
    when 'Ballot'
      self.ballot_id = updated_item.id
    when 'Comment'
      self.comment_id = updated_item.id
    when 'Post'
      self.post_id = updated_item.id
    else
      raise 'unexpected item class'
    end
  end

  private

  def ballot_category_is_not_election
    return unless ballot_id

    if ballot.election?
      errors.add :base, "Elections can't be flagged"
    end
  end

  def exactly_one_item
    unless item
      errors.add :base, "must have exactly one item"
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
