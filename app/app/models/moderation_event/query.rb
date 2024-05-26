class ModerationEvent::Query
  ALLOWED_ATTRIBUTES = [
    :action,
    :created_at,
    :id,
    :moderatable_id,
    :moderatable_type,
    :user_id,
    'users.pseudonym' => :user_pseudonym,
  ].freeze

  def self.build(initial_moderation_events, params={})
    unless initial_moderation_events
      return ModerationEvent.none.page(params[:page]).without_count
    end

    now = Time.now
    now_iso8601 = now.iso8601(6)

    created_at_or_before_param = params[:created_at_or_before] || now_iso8601
    created_at_or_before = Time.iso8601(created_at_or_before_param.to_s).utc

    moderation_events = initial_moderation_events
      .created_at_or_before(created_at_or_before)
      .joins(:user)
      .select(ALLOWED_ATTRIBUTES)
      .order(created_at: :desc)
      .page(params[:page]).without_count

    moderation_events
  end
end
