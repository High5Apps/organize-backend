class User::Query
  ALLOWED_ATTRIBUTES = [
    :connection_count,
    :id,
    :joined_at,
    :offices,
    :pseudonym,
    :recruit_count,
  ]

  def self.build(params={}, initial_users: nil)
    initial_users ||= User.all

    now = Time.now

    joined_at_or_before_param = params[:joined_at_or_before] || now
    joined_at_or_before = Time.parse(joined_at_or_before_param.to_s).utc

    users = initial_users
      .joined_at_or_before(joined_at_or_before)
      .with_service_stats
      .select(ALLOWED_ATTRIBUTES)

    sort_parameter = params[:sort]
    if sort_parameter == 'service'
      users = users.order_by_service(joined_at_or_before)
    end

    users
  end
end
