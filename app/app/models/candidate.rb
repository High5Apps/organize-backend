class Candidate < ApplicationRecord
  include Encryptable

  scope :left_outer_joins_with_most_recent_unnested_votes, -> {
    joins(%Q(
      LEFT OUTER JOIN (
        #{Vote.most_recent_unnested.to_sql}
      ) AS votes
        ON votes.unnested_candidate_id = candidates.id
    ).gsub(/\s+/, ' '))
  }

  MAX_TITLE_LENGTH = 60

  belongs_to :ballot

  validates :ballot, presence: true

  has_encrypted :title, present: true, max_length: MAX_TITLE_LENGTH
end
