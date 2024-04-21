class Org < ApplicationRecord
  include Encryptable

  MAX_NAME_LENGTH = 35
  MAX_MEMBER_DEFINITION_LENGTH = 75

  has_many :permissions
  has_many :posts
  has_many :users

  has_many :ballots, through: :users
  has_many :comments, through: :posts
  has_many :terms, through: :users

  has_encrypted :name, present: true, max_length: MAX_NAME_LENGTH
  has_encrypted :member_definition,
    present: true,
    max_length: MAX_MEMBER_DEFINITION_LENGTH

  def graph
    connections = Connection.where(scanner_id: user_ids).or(
      Connection.where(sharer_id: user_ids)
    ).pluck :sharer_id, :scanner_id

    { connections:, user_ids: }
  end

  def next_pseudonym
    seed = id.gsub("-", "").hex
    user_count = users.count
    User::Pseudonym.new(seed).at(user_count)
  end
end
