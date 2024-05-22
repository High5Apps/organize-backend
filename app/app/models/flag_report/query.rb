class FlagReport::Query
  def initialize(org, params={})
    @org = org
    @params = params
  end

  def relation
    return ApplicationRecord.none unless @org

    now = Time.now

    created_at_or_before_param = @params[:created_at_or_before] ||
      now.iso8601(6)
    created_at_or_before = Time.iso8601(created_at_or_before_param.to_s).utc

    recent_events = @org.moderation_events
      .most_recent_created_at_or_before(created_at_or_before)
      .joins(:user)
      .select('users.pseudonym AS moderator_pseudonym')

    flag_counts = @org.flags
      .created_at_or_before(created_at_or_before)
      .select(:flaggable_id, :flaggable_type, 'COUNT(*) as flag_count')
      .group(:flaggable_id, :flaggable_type)

    @relation = @org.flags
      .created_at_or_before(created_at_or_before)
      .with(flag_counts:)
      .joins(%(
        LEFT JOIN flag_counts
          ON flag_counts.flaggable_type = flags.flaggable_type
            AND flag_counts.flaggable_id = flags.flaggable_id
      ).gsub(/\s+/, ' '))
      .with(recent_events:)
      .joins(%(
        LEFT JOIN recent_events
          ON recent_events.moderatable_type = flags.flaggable_type
            AND recent_events.moderatable_id = flags.flaggable_id
      ).gsub(/\s+/, ' '))
      .select(
        # Flaggable info
        :flaggable_type,
        :flaggable_id,

        :flag_count,

        # Most recent moderation event info
        :action,
        'recent_events.created_at AS moderated_at',
        'recent_events.id AS moderation_event_id',
        'recent_events.user_id AS moderator_id',
        :moderator_pseudonym,
      )
      .page(@params[:page]).without_count

    # Default to sorting by top
    sort_parameter = @params[:sort] || 'top'
    if sort_parameter == 'top'
      @relation = @relation.order flag_count: :desc, flaggable_id: :desc
    end

    @relation = @relation.includes(flaggable: :user)
  end

  def flag_reports
    relation.map do |aggregate|
      flaggable = aggregate.flaggable
      creator = flaggable.user
      {
        flaggable: {
          category: aggregate.flaggable_type,
          creator: {
            id: creator.id,
            pseudonym: creator.pseudonym,
          },
          encrypted_title: flaggable.encrypted_flaggable_title,
          id: aggregate.flaggable_id,
        },
        flag_count: aggregate.flag_count,
        moderation_event: aggregate.moderation_event_id && {
          action: ModerationEvent.actions.key(aggregate.action),
          created_at: aggregate.moderated_at,
          id: aggregate.moderation_event_id,
          moderator: {
            id: aggregate.moderator_id,
            pseudonym: aggregate.moderator_pseudonym,
          },
        }
      }
    end
  end
end
