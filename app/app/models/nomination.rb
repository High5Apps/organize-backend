class Nomination < ApplicationRecord
  belongs_to :ballot
  belongs_to :nominator, class_name: 'User'
  belongs_to :nominee, class_name: 'User'

  validates :ballot, presence: true
  validates :nominator, presence: true
  validates :nominee,
    presence: true,
    uniqueness: { scope: :ballot }

  validate :not_self_nomination

  private

  def not_self_nomination
    return unless nominator && nominee
    if nominator == nominee
      errors.add :base, "Can't nominate yourself"
    end
  end
end
