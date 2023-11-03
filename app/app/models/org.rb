class Org < ApplicationRecord
  MAX_NAME_LENGTH = 35
  MAX_POTENTIAL_MEMBER_DEFINITION_LENGTH = 75

  has_many :posts
  has_many :users

  validates :name,
    presence: true,
    length: { maximum: MAX_NAME_LENGTH }
  validates :potential_member_definition,
    presence: true,
    length: { maximum: MAX_POTENTIAL_MEMBER_DEFINITION_LENGTH }

  validate :encrypted_name_ciphertext_length_within_range

  serialize :encrypted_name, EncryptedMessage

  def graph
    recruit_counts = users.joins(:recruits).group(:id).count
    scanned_connection_counts =
      users.joins(:scanned_connections).group(:id).count
    shared_connection_counts =
      users.joins(:shared_connections).group(:id).count
    offices = users.joins(:offices).group('users.id')
      .pluck('users.id', 'array_agg(offices.name)').to_h
    user_data = users.pluck :id, :joined_at, :pseudonym
    user_entries = user_data.map do |d|
      id = d[0];
      connection_count = (scanned_connection_counts[id] || 0) +
        (shared_connection_counts[id] || 0)
      [
        id,
        {
        connection_count: connection_count,
        id: id,
        joined_at: d[1].to_f,
        offices: offices[id],
        pseudonym: d[2],
        recruit_count: recruit_counts[id] || 0,
        },
      ]
    end

    nodes = user_entries.to_h

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

  private

  def encrypted_name_ciphertext_length_within_range
    length = encrypted_name.decoded_ciphertext_length
    return errors.add(:encrypted_name, "can't be blank") unless length > 0
    errors.add(:encrypted_name, 'is too long') if length > MAX_NAME_LENGTH
  end
end
