class Org < ApplicationRecord
  MAX_NAME_LENGTH = 35
  MAX_POTENTIAL_MEMBER_DEFINITION_LENGTH = 75
  MIN_POTENTIAL_MEMBER_ESTIMATE = 2
  MAX_POTENTIAL_MEMBER_ESTIMATE = 99999

  has_many :users

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

  def graph
    user_ids = users.ids
    connections = Connection.where(scanner_id: user_ids).or(
      Connection.where(sharer_id: user_ids)
    ).pluck :sharer_id, :scanner_id

    {
      user_ids: user_ids,
      connections: connections,
    }
  end
  
  def next_pseudonym
    seed = id.gsub("-", "").hex
    user_count = users.count
    Users::Pseudonym.new(seed).at(user_count)
  end
end
