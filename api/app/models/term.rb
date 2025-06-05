class Term < ApplicationRecord
  scope :accepted, -> { where(accepted: true) }
  scope :active_at, ->(time) {
    accepted.where(starts_at: ..time).where.not(ends_at: ..time)
  }
  scope :impending_at, ->(time) {
    accepted.where.not(starts_at: ..time)
  }

  # Do not use 2.months for this because it creates test failures near the end
  # of months that are not 30-days long
  COOLDOWN_PERIOD = 60.days

  enum :office, Office::TYPE_SYMBOLS, validate: true

  belongs_to :ballot, optional: true
  belongs_to :user

  validates :accepted, inclusion: { in: [true, false] }
  validates :ballot, absence: true, if: :founder?
  validates :ballot, presence: true, same_org: :user, unless: :founder?
  validates :ends_at,
    presence: true,
    comparison: { greater_than: :starts_at }
  validates :starts_at, presence: true
  validates :starts_at,
    after_created_at: true,
    unless: :founder?
  validates :user, presence: true

  validate :user_is_first_member, if: :founder?
  validate :user_won_election, unless: :founder?

  before_validation :set_ballot_info, on: :create, unless: :founder?

  private

  def set_ballot_info
    return unless ballot

    self.ends_at = ballot.term_ends_at
    self.office = ballot.office
    self.starts_at = ballot.term_starts_at
  end

  def user_is_first_member
    return unless user

    unless user.org
      errors.add :user, :not_in_org
      return
    end

    unless user == user.org.users.order(:joined_at).first
      errors.add :user, :founder_not_first_member
    end
  end

  def user_won_election
    return unless ballot && user

    candidate_id = ballot.candidates.where(user:).first&.id
    unless ballot.winner? candidate_id
      errors.add :user, :lost_election
    end
  end
end
