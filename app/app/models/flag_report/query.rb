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

    @relation = @org.flags
      .includes(flaggable: [{ last_moderation_event: :user }, :user])
      .created_at_or_before(created_at_or_before)
      .select(:flaggable_id, :flaggable_type, 'COUNT(*) as flag_count')
      .group(:flaggable_id, :flaggable_type)
      .page(@params[:page]).without_count

    # Default to sorting by top
    sort_parameter = @params[:sort] || 'top'
    if sort_parameter == 'top'
      @relation = @relation.order flag_count: :desc, flaggable_id: :desc
    end

    @relation
  end

  def flag_reports
    relation.map do |flag|
      flaggable = flag.flaggable
      creator = flaggable.user
      last_moderation_event = flaggable.last_moderation_event
      {
        flaggable: {
          category: flag.flaggable_type,
          creator: {
            id: creator.id,
            pseudonym: creator.pseudonym,
          },
          encrypted_title: flaggable.encrypted_flaggable_title,
          id: flag.flaggable_id,
        },
        flag_count: flag.flag_count,
        moderation_event: last_moderation_event && {
          action: last_moderation_event.action,
          created_at: last_moderation_event.created_at,
          id: last_moderation_event.id,
          moderator: {
            id: last_moderation_event.user.id,
            pseudonym: last_moderation_event.user.pseudonym,
          },
        }
      }
    end
  end
end
