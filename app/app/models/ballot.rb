class Ballot < ApplicationRecord
  include Encryptable

  scope :active_at, ->(time) { where.not(voting_ends_at: ..time) }
  scope :created_before, ->(time) { where(created_at: ...time) }
  scope :inactive_at, ->(time) { where(voting_ends_at: ..time) }

  MAX_QUESTION_LENGTH = 140

  enum category: [:yes_no, :multiple_choice, :election]
  enum office: Office::TYPE_SYMBOLS

  belongs_to :user

  has_many :candidates
  has_many :votes

  has_one :org, through: :user

  validates :category,
    presence: true,
    inclusion: { in: categories }
  validates :max_candidate_ids_per_vote,
    numericality: { allow_nil: true, greater_than: 0, only_integer: true }
  validates :office, inclusion: { in: offices }, if: :election?
  validates :nominations_end_at,
    presence: true,
    after_created_at: true,
    if: :election?
  validates :user, presence: true
  validates :term_ends_at,
    presence: true,
    comparison: {
      greater_than: :voting_ends_at,
      message: 'must be after voting end',
    },
    if: :election?
  validates :voting_ends_at, presence: true
  validates :voting_ends_at, after_created_at: true, unless: :election?
  validates :voting_ends_at,
    comparison: {
      greater_than: :nominations_end_at,
      message: 'must be after nominations end',
    },
    if: :election?

  has_encrypted :question, present: true, max_length: MAX_QUESTION_LENGTH

  def results
    candidates.left_outer_joins_with_most_recent_unnested_votes
      .group(:id)
      .order(count_unnested_candidate_id: :desc, id: :desc)
      # Note that it's important to count :unnested_candidate_id instead of :all
      # or :candidate_id, because of the left join. Otherwise, every candidate
      # would receive at least one vote.
      .count(:unnested_candidate_id)
      .map { |candidate_id, vote_count| { candidate_id:, vote_count: } }
  end
end
