class User::Query
  ALLOWED_ATTRIBUTES = [
    :id,
    :joined_at,
    :pseudonym,
  ]

  def self.build(params={}, initial_users: nil)
    initial_users ||= User.all

    users = initial_users.select(ALLOWED_ATTRIBUTES)

    users
  end
end
