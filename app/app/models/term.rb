class Term < ApplicationRecord
  scope :active_at, ->(time) {
    where(accepted: true, starts_at: ..time).where.not(ends_at: ..time)
  }

  COOLDOWN_PERIOD = 2.months

  enum office: Office::TYPE_SYMBOLS

  belongs_to :ballot, optional: true
  belongs_to :user

  validates :accepted, inclusion: { in: [true, false] }
  validates :ballot, absence: true, if: :founder?
  validates :ballot, presence: true, unless: :founder?
  validates :ends_at,
    presence: true,
    comparison: { greater_than: :starts_at }
  validates :office,
    presence: true,
    inclusion: { in: offices }
  validates :starts_at, presence: true
  validates :starts_at,
    after_created_at: true,
    unless: :founder?
  validates :user, presence: true

  validate :user_is_first_member, if: :founder?
  validate :user_won_election, unless: :founder?

  private

  def user_is_first_member
    return unless user

    unless user.org
      errors.add :user, 'must be a member of an Org'
    end

    unless user == user.org.users.order(:created_at).first
      errors.add :user, "must be the Org's first member to be the founder"
    end
  end

  def user_won_election
    return unless ballot && user

    candidate_id = ballot.candidates.where(user:).first&.id
    unless ballot.winner? candidate_id
      errors.add :user, 'must have won the election'
    end
  end
end
