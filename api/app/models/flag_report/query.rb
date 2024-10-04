class FlagReport::Query
  UNHANDLED_ACTIONS = ['undo_allow', 'undo_block'].freeze
  UNHANDLED_ACTION_VALUES = UNHANDLED_ACTIONS
    .map { |action| ModerationEvent.actions[action] }
    .freeze

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

    handled = ActiveModel::Type::Boolean.new.deserialize @params[:handled]

    recent_events = @org.moderation_events
      .most_recent_created_at_or_before(created_at_or_before)
      .joins(:user)
      .select('moderation_events.*', 'users.pseudonym AS moderator_pseudonym')

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
      ).squish)
      .with(recent_events:)

    # When handled is true, INNER JOIN to only include flaggables with
    # moderation events, then filter out unhandled moderation event actions, and
    # order by most recent moderation event creation
    if handled
      @relation = @relation.joins(%(
        INNER JOIN recent_events
          ON recent_events.moderatable_type = flags.flaggable_type
            AND recent_events.moderatable_id = flags.flaggable_id
      ).squish)
        .where.not(recent_events: { action: UNHANDLED_ACTION_VALUES })
        .order('recent_events.created_at DESC, recent_events.id DESC')
    else
      # When handled is nil or false, LEFT JOIN to include all flaggables
      # regardless of whether they have moderation events, and order by most
      # flags
      @relation = @relation.joins(%(
        LEFT JOIN recent_events
          ON recent_events.moderatable_type = flags.flaggable_type
            AND recent_events.moderatable_id = flags.flaggable_id
      ).squish)
        .order flag_count: :desc, flaggable_id: :desc

      # When handled is false, only include flaggables without moderation events
      # or flaggables with unhandled moderation event actions
      if handled == false
        @relation = @relation.where(recent_events: { id: nil })
          .or(
            @relation.where(recent_events: { action: UNHANDLED_ACTION_VALUES }))
      end
    end

    @relation = @relation.select(
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
      ).distinct
      .page(@params[:page]).without_count

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
          deleted_at: flaggable.try(:deleted_at),
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
