class Vote < ApplicationRecord
  MAX_CANDIDATE_IDS_PER_VOTE = 1

  belongs_to :ballot
  belongs_to :user

  validates :ballot, presence: true
  validates :candidate_ids,
    length: { minimum: 0, maximum: MAX_CANDIDATE_IDS_PER_VOTE }
  validates :user, presence: true

  validate :candidates_are_a_subset_of_ballot_candidates

  private

  def candidates_are_a_subset_of_ballot_candidates
    return if ballot.blank? || candidate_ids.blank?

    ballot_candidate_id_set = ballot.candidates.ids.to_set
    candidate_id_set = candidate_ids.to_set
    unless candidate_id_set.subset? ballot_candidate_id_set
      errors.add(:candidate_ids, "must be a subset of ballot's candidates")
    end
  end
end
