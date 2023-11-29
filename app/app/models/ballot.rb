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
    votes.most_recent
      .group(:candidate_id)
      .order(vote_count: :desc)
      .pluck('unnest(candidate_ids) as candidate_id, count(1) as vote_count')
      .to_h
      .reverse_merge(candidates.pluck('id, 0').to_h)
      .map do |candidate_id, vote_count|
        { candidate_id: candidate_id, vote_count: vote_count }
      end
  end
end
