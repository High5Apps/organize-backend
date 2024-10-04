class Post < ApplicationRecord
  include Encryptable
  include Flaggable

  scope :created_at_or_before, ->(time) { where(created_at: ..time) }

  MAX_TITLE_LENGTH = 140
  MAX_BODY_LENGTH = 10000

  enum :category, [:general, :grievances, :demands], validate: true

  belongs_to :candidate, optional: true
  belongs_to :org

  has_many :comments
  has_many :upvotes

  validates :org, presence: true, same_org: :user

  validate :candidacy_announcement_category_is_general
  validate :candidacy_announcement_created_by_candidate
  validate :candidacy_announcement_created_before_vote_ends, on: :create

  before_validation :set_org_id_from_user, on: :create
  after_create :create_upvote_for_user

  has_encrypted :title, present: true, max_length: MAX_TITLE_LENGTH
  has_encrypted :body, max_length: MAX_BODY_LENGTH
  flaggable title: :encrypted_title

  private

  def candidacy_announcement_category_is_general
    return unless candidate_id

    unless general?
      errors.add :category, 'must be "general" for candidacy announcements'
    end
  end

  def candidacy_announcement_created_before_vote_ends
    return unless candidate_id

    unless Time.now < candidate.ballot.voting_ends_at
      errors.add :base, "Can't create candidacy announcement after voting ends"
    end
  end

  def candidacy_announcement_created_by_candidate
    return unless candidate_id

    unless user_id == candidate.user_id
      errors.add :base,
        'Candidacy announcement can only be created by the candidate'
    end
  end

  def create_upvote_for_user
    upvotes.create! user:, value: 1
  end

  def set_org_id_from_user
    self.org_id = user&.org_id
  end
end
