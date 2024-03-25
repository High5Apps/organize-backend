class Vote < ApplicationRecord
  scope :unnested, -> {
    select('*').joins(%Q(
      JOIN (
        #{select('*, unnest(candidate_ids) as unnested_candidate_id').to_sql}
      ) AS unnested_votes
        ON unnested_votes.id = votes.id
    ).gsub(/\s+/, ' '))
  }

  belongs_to :ballot
  belongs_to :user

  validates :ballot, presence: true
  validates :candidate_ids,
    length: { minimum: 0, allow_nil: false }
  validates :user, presence: true

  validate :candidates_are_a_subset_of_ballot_candidates
  validate :no_duplicates
  validate :not_overvoting
  validate :user_and_ballot_in_same_org

  after_save :validate_saved_after_nominations_end
  after_save :validate_saved_before_voting_ends

  private

  def candidates_are_a_subset_of_ballot_candidates
    return if ballot.blank? || candidate_ids.blank?

    ballot_candidate_id_set = ballot.candidates.ids.to_set
    candidate_id_set = candidate_ids.to_set
    unless candidate_id_set.subset? ballot_candidate_id_set
      errors.add(:candidate_ids, "must be a subset of ballot's candidates")
    end
  end

  def no_duplicates
    return if candidate_ids.blank?

    unless candidate_ids.uniq.length == candidate_ids.length
      errors.add(:candidate_ids, 'must not contain duplicates')
    end
  end

  def not_overvoting
    return if ballot.blank? || candidate_ids.blank?

    max = ballot.max_candidate_ids_per_vote
    if candidate_ids.length > max
      errors.add :base,
        "must not contain more than #{max} #{'choice'.pluralize(max)}"
    end
  end

  def user_and_ballot_in_same_org
    return if ballot.blank? || user.blank?
    errors.add :ballot, 'not found' unless user.org.id == ballot.org.id
  end

  def validate_saved_after_nominations_end
    return unless ballot

    if ballot.nominations_end_at && (updated_at < ballot.nominations_end_at)
      errors.add(:base, "Vote can't be created before nominations end")
      raise ActiveRecord::RecordInvalid
    end
  end

  def validate_saved_before_voting_ends
    return unless ballot

    unless updated_at < ballot.voting_ends_at
      errors.add(:base, "Vote can't be changed after voting ends")
      raise ActiveRecord::RecordInvalid
    end
  end
end
