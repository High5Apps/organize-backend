class Nomination < ApplicationRecord
  belongs_to :ballot
  belongs_to :nominator, class_name: 'User'
  belongs_to :nominee, class_name: 'User'

  has_one :candidate

  validates :ballot, presence: true
  validates :nominator, presence: true
  validates :nominee,
    presence: true,
    uniqueness: { scope: :ballot }

  validate :not_self_nomination

  before_validation :check_unaccepted, if: :will_save_change_to_accepted?
  after_update :create_candidate_for_nominee,
    if: -> { saved_change_to_accepted? from: nil, to: true }

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
end
