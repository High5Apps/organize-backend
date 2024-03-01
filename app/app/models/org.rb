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
    now = Time.now
    users_with_stats = users.joined_at_or_before(now)
      .with_service_stats(now)
      .order_by_office(now)
      .select(User::Query::ALLOWED_ATTRIBUTES)
    nodes = users_with_stats.map{|u| [u.id, u] }.to_h

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
