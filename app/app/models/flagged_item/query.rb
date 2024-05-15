class FlaggedItem::Query
  def initialize(initial_flagged_items, params={})
    @initial_flagged_items = initial_flagged_items
    @params = params
  end

  def relation
    return @relation if @relation

    @relation = FlaggedItem.none unless @initial_flagged_items
    return @relation if @relation

    now = Time.now

    created_at_or_before_param = @params[:created_at_or_before] || now
    created_at_or_before = Time.parse(created_at_or_before_param.to_s).utc

    flagged_items = @initial_flagged_items
      .includes(flaggable: :user)
      .created_at_or_before(created_at_or_before)
      .select(:flaggable_id, :flaggable_type, 'COUNT(*) as flag_count')
      .group(:flaggable_id, :flaggable_type)
      .page(@params[:page]).without_count

    # Default to sorting by top
    sort_parameter = @params[:sort] || 'top'
    if sort_parameter == 'top'
      flagged_items = flagged_items.order('flag_count DESC, flaggable_id DESC')
    end

    @relation = flagged_items
  end

  def flag_reports
    relation.map do |item|
      {
        category: item.flaggable_type,
        encrypted_title: item.flaggable.encrypted_flaggable_title,
        flag_count: item.flag_count,
        id: item.flaggable_id,
        pseudonym: item.flaggable.user.pseudonym,
        user_id: item.flaggable.user.id,
      }
    end
  end
end
