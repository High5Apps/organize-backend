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
    recruit_counts = users.joins(:recruits).group(:id).count
    scanned_connection_counts =
      users.joins(:scanned_connections).group(:id).count
    shared_connection_counts =
      users.joins(:shared_connections).group(:id).count
    user_data = users.pluck :id, :joined_at, :pseudonym
    nodes = user_data.map do |d|
      id = d[0];
      connection_count = (scanned_connection_counts[id] || 0) +
        (shared_connection_counts[id] || 0)
      {
        connection_count: connection_count,
        id: id,
        joined_at: d[1].to_f,
        pseudonym: d[2],
        recruit_count: recruit_counts[id] || 0,
      }
    end

    connections = Connection.where(scanner_id: user_ids).or(
      Connection.where(sharer_id: user_ids)
    ).pluck :sharer_id, :scanner_id

    {
      users: nodes,
      connections: connections,
    }
  end
  
  def next_pseudonym
    seed = id.gsub("-", "").hex
    user_count = users.count
    Users::Pseudonym.new(seed).at(user_count)
  end
end
