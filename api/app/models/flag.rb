class Flag < ApplicationRecord
  scope :created_at_or_before, ->(time) { where(created_at: ..time) }

  ALLOWED_TYPES = ['Ballot', 'Comment', 'Post']

  belongs_to :flaggable, polymorphic: true
  belongs_to :user

  validates :flaggable, same_org: { as: :user, name: 'Item' }
  validates :flaggable_type, inclusion: { in: ALLOWED_TYPES }
  validates :user, presence: true

  validate :ballot_category_is_not_election
  validate :post_is_not_candidacy_announcement

  private

  def ballot_category_is_not_election
    return unless flaggable_type == 'Ballot'

    if flaggable.election?
      errors.add :base, "Elections can't be flagged"
    end
  end

  def post_is_not_candidacy_announcement
    return unless flaggable_type == 'Post'

    if flaggable.candidate_id
      errors.add :base, "Candidacy announcements can't be flagged"
    end
  end
end
