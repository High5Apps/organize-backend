class Org < ApplicationRecord
  include Encryptable

  MAX_NAME_LENGTH = 35
  MAX_MEMBER_DEFINITION_LENGTH = 75

  has_many :posts
  has_many :users

  has_many :ballots, through: :users
  has_many :terms, through: :users

  has_encrypted :name, present: true, max_length: MAX_NAME_LENGTH
  has_encrypted :member_definition,
    present: true,
    max_length: MAX_MEMBER_DEFINITION_LENGTH

  def graph
    recruit_counts = users.joins(:recruits).group(:id).count
    scanned_connection_counts =
      users.joins(:scanned_connections).group(:id).count
    shared_connection_counts =
      users.joins(:shared_connections).group(:id).count
    offices = terms.group('terms.user_id')
      .pluck('terms.user_id', 'array_agg(terms.office)').to_h
      .transform_values { |arr| arr.sort.map {|v| Office.new(v).title } }
    user_data = users.pluck :id, :joined_at, :pseudonym
    user_entries = user_data.map do |d|
      id = d[0];
      connection_count = (scanned_connection_counts[id] || 0) +
        (shared_connection_counts[id] || 0)
      [
        id,
        {
          connection_count:,
          id:,
          joined_at: d[1],
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
      connections:,
    }
  end

  def next_pseudonym
    seed = id.gsub("-", "").hex
    user_count = users.count
    User::Pseudonym.new(seed).at(user_count)
  end
end
