class Ballot::Query
  ALLOWED_ATTRIBUTES = [
    :category,
    :encrypted_question,
    :id,
    :nominations_end_at,
    :office,
    :user_id,
    :voting_ends_at,
  ]

  def self.build(params={}, initial_ballots: nil)
    initial_ballots ||= Ballot.all

    now = Time.now

    created_at_or_before_param = params[:created_at_or_before] || now
    created_at_or_before = Time.parse(created_at_or_before_param.to_s).utc

    ballots = initial_ballots
      .created_at_or_before(created_at_or_before)
      .select(ALLOWED_ATTRIBUTES)

    active_at_param = params[:active_at]
    if active_at_param
      active_at = Time.parse(active_at_param.to_s).utc
      ballots = ballots.active_at(active_at)
    end

    inactive_at_param = params[:inactive_at]
    if inactive_at_param
      inactive_at = Time.parse(inactive_at_param.to_s).utc
      ballots = ballots.inactive_at(inactive_at)
    end

    page_param = params[:page]
    if page_param
      ballots = ballots.page(page_param).without_count
    end

    # Default to sorting by active
    sort_parameter = params[:sort] || 'active'
    if sort_parameter == 'active'
      ballots = ballots.order_by_active(active_at || now)
    elsif sort_parameter == 'inactive'
      ballots = ballots.order_by_inactive
    end

    ballots
  end
end
