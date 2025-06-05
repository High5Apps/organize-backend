class Post < ApplicationRecord
  include Encryptable
  include Flaggable

  scope :created_at_or_before, ->(time) { where(created_at: ..time) }

  MAX_TITLE_LENGTH = 140
  MAX_BODY_LENGTH = 10000

  enum :category, [:general, :grievances, :demands], validate: true

  belongs_to :candidate, optional: true

  has_many :comments
  has_many :upvotes

  validates :candidate, uniqueness: true, if: :candidate_id?

  validate :candidacy_announcement_category_is_general
  validate :candidacy_announcement_created_by_candidate
  validate :candidacy_announcement_created_before_vote_ends, on: :create

  after_create :create_upvote_for_user

  has_encrypted :title, present: true, max_length: MAX_TITLE_LENGTH
  has_encrypted :body, max_length: MAX_BODY_LENGTH
  flaggable title: :encrypted_title

  private

  def candidacy_announcement_category_is_general
    return unless candidate_id

    unless general?
      errors.add :category, :not_general_for_candidacy_announcement
    end
  end

  def candidacy_announcement_created_before_vote_ends
    return unless candidate_id

    unless Time.now < candidate.ballot.voting_ends_at
      errors.add :base, :candidacy_announcement_created_after_voting_end
    end
  end

  def candidacy_announcement_created_by_candidate
    return unless candidate_id

    unless user_id == candidate.user_id
      errors.add :base, :candidacy_announcement_not_created_by_candidate
    end
  end

  def create_upvote_for_user
    upvotes.create! user:, value: 1
  end
end
