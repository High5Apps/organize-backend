class FlagReport::Query
  def initialize(initial_flags, params={})
    @initial_flags = initial_flags
    @params = params
  end

  def relation
    return @relation if @relation

    @relation = Flag.none unless @initial_flags
    return @relation if @relation

    now = Time.now

    created_at_or_before_param = @params[:created_at_or_before] || now
    created_at_or_before = Time.parse(created_at_or_before_param.to_s).utc

    flags = @initial_flags
      .includes(flaggable: [{ last_moderation_event: :user }, :user])
      .created_at_or_before(created_at_or_before)
      .select(:flaggable_id, :flaggable_type, 'COUNT(*) as flag_count')
      .group(:flaggable_id, :flaggable_type)
      .page(@params[:page]).without_count

    # Default to sorting by top
    sort_parameter = @params[:sort] || 'top'
    if sort_parameter == 'top'
      flags = flags.order('flag_count DESC, flaggable_id DESC')
    end

    @relation = flags
  end

  def flag_reports
    relation.map do |flag|
      flaggable = flag.flaggable
      creator = flaggable.user
      last_moderation_event = flaggable.last_moderation_event
      {
        category: flag.flaggable_type,
        creator: {
          id: creator.id,
          pseudonym: creator.pseudonym,
        },
        encrypted_title: flaggable.encrypted_flaggable_title,
        flag_count: flag.flag_count,
        id: flag.flaggable_id,
        moderation_event: last_moderation_event && {
          action: last_moderation_event.action,
          created_at: last_moderation_event.created_at,
          moderator: {
            id: last_moderation_event.user.id,
            pseudonym: last_moderation_event.user.pseudonym,
          },
        }
      }
    end
  end
end
