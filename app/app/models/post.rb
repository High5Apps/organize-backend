class Post < ApplicationRecord
  include Encryptable

  scope :created_at_or_before, ->(time) { where(created_at: ..time) }
  scope :left_outer_joins_with_most_recent_upvotes_created_at_or_before, ->(time) {
    joins(%Q(
      LEFT OUTER JOIN (
        #{Upvote.most_recent_created_at_or_before(time).to_sql}
      ) AS upvotes
        ON upvotes.post_id = posts.id
    ).gsub(/\s+/, ' '))
  }

  MAX_TITLE_LENGTH = 140
  MAX_BODY_LENGTH = 10000

  enum category: [:general, :grievances, :demands]

  belongs_to :candidate, optional: true
  belongs_to :org
  belongs_to :user

  has_many :comments
  has_many :upvotes

  validates :org, presence: true
  validates :category,
    presence: true,
    inclusion: { in: categories }
  validates :user, presence: true

  validate :candidacy_announcement_category_is_general
  validate :candidacy_announcement_created_by_candidate
  validate :candidacy_announcement_created_before_vote_ends, on: :create

  after_create :create_upvote_for_user

  has_encrypted :title, present: true, max_length: MAX_TITLE_LENGTH
  has_encrypted :body, max_length: MAX_BODY_LENGTH

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
end
