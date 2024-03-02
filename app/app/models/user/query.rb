class User::Query
  ALLOWED_ATTRIBUTES = [
    :connection_count,
    :id,
    :joined_at,
    :offices,
    :pseudonym,
    :recruit_count,
  ]
  PAGINATION_BYPASSING_FILTERS = ['officer']

  def initialize(params={}, initial_users: nil)
    @params = params
    @initial_users = initial_users || User.all
  end

  def paginates?
    values = relation.values
    (values[:limit] && values[:offset]) != nil
  end

  def relation
    return @relation if @relation

    now = Time.now

    joined_at_or_before_param = @params[:joined_at_or_before] || now
    joined_at_or_before = Time.parse(joined_at_or_before_param.to_s).utc

    users = @initial_users
      .joined_at_or_before(joined_at_or_before)
      .with_service_stats
      .select(ALLOWED_ATTRIBUTES)

    filter_parameter = @params[:filter]

    unless PAGINATION_BYPASSING_FILTERS.include? filter_parameter
      users = users.page(@params[:page])
    end

    if filter_parameter == 'officer'
      users = users.officers
    end

    sort_parameter = @params[:sort]
    if sort_parameter == 'service'
      users = users.order_by_service(joined_at_or_before)
    elsif sort_parameter == 'office'
      users = users.order_by_office(joined_at_or_before)
    end

    @relation = users
    @relation
  end
end
