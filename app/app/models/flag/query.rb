class Flag::Query
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
      .includes(flaggable: :user)
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
      {
        category: flag.flaggable_type,
        encrypted_title: flag.flaggable.encrypted_flaggable_title,
        flag_count: flag.flag_count,
        id: flag.flaggable_id,
        pseudonym: flag.flaggable.user.pseudonym,
        user_id: flag.flaggable.user.id,
      }
    end
  end
end
