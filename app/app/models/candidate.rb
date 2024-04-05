class Candidate < ApplicationRecord
  include Encryptable

  scope :left_outer_joins_with_unnested_votes, -> {
    with(votes: Vote.unnested_candidate_ids)
      .left_outer_joins(:votes)
  }

  MAX_TITLE_LENGTH = 60

  belongs_to :ballot
  belongs_to :nomination, optional: true
  belongs_to :user, optional: true

  has_one :post

  validates :ballot, presence: true
  validates :nomination, absence: true, unless: -> { ballot&.election? }
  validates :nomination, presence: true, if: -> { ballot&.election? }
  validates :user, absence: true, unless: -> { ballot&.election? }
  validates :user, presence: true, if: -> { ballot&.election? }

  validate :encrypted_title_absent, if: -> { ballot&.election? }
  validate :encrypted_title_present, unless: -> { ballot&.election? }
  validate :nomination_matches_candidate,
    if: :will_save_change_to_nomination_id?

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

  def nomination_matches_candidate
    return unless ballot && nomination && user
    unless ballot == nomination.ballot && user == nomination.nominee
      errors.add :base, "Nomination's nominee and ballot must match candidate"
    end
  end
end
