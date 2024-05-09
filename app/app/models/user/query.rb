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

  def initialize(initial_users, params={})
    @initial_users = initial_users
    @params = params
  end

  def paginates?
    values = relation.values
    (values[:limit] && values[:offset]) != nil
  end

  def relation
    return @relation if @relation

    users = unpaginated_relation
    users = paginate(users) if paginate?

    @relation = users
    @relation
  end

  private

  def filter_parameter
    @params[:filter]
  end

  def paginate(users)
    users.page(@params[:page]).without_count
  end

  def paginate?
    !PAGINATION_BYPASSING_FILTERS.include? filter_parameter
  end

  def unpaginated_relation
    return User.none unless @initial_users

    now = Time.now

    joined_at_or_before_param = @params[:joined_at_or_before] || now
    joined_at_or_before = Time.parse(joined_at_or_before_param.to_s).utc

    users = @initial_users
      .joined_at_or_before(joined_at_or_before)
      .with_service_stats
      .select(ALLOWED_ATTRIBUTES)

    if filter_parameter == 'officer'
      users = users.officers
    end

    query_parameter = @params[:query]
    if query_parameter
      users = users.search_by_pseudonym query_parameter
    end

    sort_parameter = @params[:sort]
    if sort_parameter == 'service'
      users = users.order_by_service(joined_at_or_before)
    elsif sort_parameter == 'office'
      users = users.order_by_office(joined_at_or_before)
    end

    users
  end
end
