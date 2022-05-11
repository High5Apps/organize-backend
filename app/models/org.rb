class Org < ApplicationRecord
  MAX_NAME_LENGTH = 35
  MAX_POTENTIAL_MEMBER_DEFINITION_LENGTH = 75
  MIN_POTENTIAL_MEMBER_ESTIMATE = 2
  MAX_POTENTIAL_MEMBER_ESTIMATE = 99999

  validates :name,
    presence: true,
    length: { maximum: MAX_NAME_LENGTH }
  validates :potential_member_definition,
    presence: true,
    length: { maximum: MAX_POTENTIAL_MEMBER_DEFINITION_LENGTH }
  validates :potential_member_estimate,
    presence: true,
      numericality: {
        only_integer: true,
          in: MIN_POTENTIAL_MEMBER_ESTIMATE..MAX_POTENTIAL_MEMBER_ESTIMATE,
      }
end
