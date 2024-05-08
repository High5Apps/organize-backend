class Nomination < ApplicationRecord
  belongs_to :ballot
  belongs_to :nominator, class_name: 'User'
  belongs_to :nominee, class_name: 'User'

  has_one :candidate

  validates :ballot, presence: true, same_org: :nominator
  validates :nominator, presence: true
  validates :nominee,
    presence: true,
    same_org: :nominator,
    uniqueness: { scope: :ballot }

  validate :ballot_is_election
  validate :not_self_nomination

  before_validation :check_unaccepted, if: :will_save_change_to_accepted?
  after_update :create_candidate_for_nominee,
    if: -> { saved_change_to_accepted? from: nil, to: true }

  after_save :validate_saved_before_nominations_end

  private

  def check_unaccepted
    unless accepted_in_database.nil?
      errors.add :accepted, "can't be modified"
    end
  end

  def create_candidate_for_nominee
    create_candidate! ballot:, user: nominee
  end

  def not_self_nomination
    return unless nominator && nominee
    if nominator == nominee
      errors.add :base, "Can't nominate yourself"
    end
  end

  def ballot_is_election
    return unless ballot

    unless ballot.election?
      errors.add(:base, "Can't nominate candidates for non-elections")
    end
  end

  def validate_saved_before_nominations_end
    return unless ballot&.election?

    unless updated_at < ballot.nominations_end_at
      errors.add(:base, "Nomination can't be changed after nominations end")
      raise ActiveRecord::RecordInvalid
    end
  end
end
