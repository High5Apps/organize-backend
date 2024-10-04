class Vote < ApplicationRecord
  scope :unnested_candidate_ids, -> {
    with(unnested_votes:
      select('id as vote_id, unnest(candidate_ids) as candidate_id')
    )
      .joins(:unnested_votes)
      .select(:candidate_id)
  }

  belongs_to :ballot
  belongs_to :user

  validates :ballot, presence: true, same_org: :user
  validates :candidate_ids,
    length: { minimum: 0, allow_nil: false }
  validates :user, presence: true

  validate :candidates_are_a_subset_of_ballot_candidates
  validate :no_duplicates
  validate :not_overvoting

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
