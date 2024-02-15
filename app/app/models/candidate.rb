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

  validate :either_title_or_user_present

  has_encrypted :title, max_length: MAX_TITLE_LENGTH

  private

  def either_title_or_user_present
    unless (encrypted_title.blank? && !user.blank?) \
        || (!encrypted_title.blank? && user.blank?)
      errors.add :base, 'must have either title or user reference'
    end
  end
end
