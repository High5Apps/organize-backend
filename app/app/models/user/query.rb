class User::Query
  ALLOWED_ATTRIBUTES = [
    :id,
    :joined_at,
    :pseudonym,
  ]

  def self.build(params={}, initial_users: nil)
    initial_users ||= User.all

    now = Time.now

    joined_before_param = params[:joined_before] || now
    joined_before = Time.parse(joined_before_param.to_s).utc

    users = initial_users
      .joined_before(joined_before)
      .select(ALLOWED_ATTRIBUTES)

    users
  end
end
