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
  belongs_to :user, optional: true

  validates :ballot, presence: true
  validates :user, absence: true, unless: -> { ballot&.election? }
  validates :user, presence: true, if: -> { ballot&.election? }

  validate :encrypted_title_absent, if: -> { ballot&.election? }
  validate :encrypted_title_present, unless: -> { ballot&.election? }

  has_encrypted :title, max_length: MAX_TITLE_LENGTH

  private

  def encrypted_title_absent
    unless encrypted_title&.blank?
      errors.add :encrypted_title, 'Must be absent for elections'
    end
  end

  def encrypted_title_present
    if encrypted_title&.blank?
      errors.add :encrypted_title, 'Must be present for non-elections'
    end
  end
end
