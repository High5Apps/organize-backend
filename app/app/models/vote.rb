class Vote < ApplicationRecord
  scope :most_recent, -> {
    most_recent_vote_for_each_user_on_each_ballot = select(
      '*',
      %(
        FIRST_VALUE(votes.id) OVER (
          PARTITION BY votes.user_id, votes.ballot_id
          ORDER BY votes.created_at DESC, votes.id DESC
        ) AS first_id
      ).gsub(/\s+/, ' ')
    )

    from(most_recent_vote_for_each_user_on_each_ballot, :votes)
      .where('votes.id = first_id')
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

  def validate_saved_before_voting_ends
    unless updated_at < ballot.voting_ends_at
      errors.add(:base, 'must be saved before voting ends')
      raise ActiveRecord::RecordInvalid
    end
  end
end
