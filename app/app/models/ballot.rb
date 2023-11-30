class Ballot < ApplicationRecord
  include Encryptable

  scope :active_at, ->(time) { where.not(voting_ends_at: ..time) }
  scope :created_before, ->(time) { where(created_at: ...time) }
  scope :inactive_at, ->(time) { where(voting_ends_at: ..time) }

  MAX_QUESTION_LENGTH = 140

  enum category: [:yes_no]

  belongs_to :user

  has_many :candidates
  has_many :votes

  has_one :org, through: :user

  validates :category,
    presence: true,
    inclusion: { in: categories }
  validates :user, presence: true
  validates :voting_ends_at, future: true

  has_encrypted :question, present: true, max_length: MAX_QUESTION_LENGTH

  def results
    candidates.left_outer_joins_with_most_recent_unnested_votes
      .group(:id)
      .order(count_all: :desc, id: :desc)
      .count(:all)
      .map do |candidate_id, vote_count|
        { candidate_id: candidate_id, vote_count: vote_count }
      end
  end
end
