class FlaggedItem::Query
  def self.build(initial_flagged_items, params={})
    return FlaggedItem.none unless initial_flagged_items

    now = Time.now

    created_at_or_before_param = params[:created_at_or_before] || now
    created_at_or_before = Time.parse(created_at_or_before_param.to_s).utc

    relation = initial_flagged_items
      .created_at_or_before(created_at_or_before)
      .select(:flaggable_id, :flaggable_type, 'COUNT(*) as flag_count')
      .group(:flaggable_id, :flaggable_type)
      .page(params[:page]).without_count

    # Default to sorting by top
    sort_parameter = params[:sort] || 'top'
    if sort_parameter == 'top'
      relation = relation.order('flag_count DESC, flaggable_id DESC')
    end

    flagged_items = relation.includes(flaggable: :user).map do |item|
      {
        category: item.flaggable_type,
        encrypted_title: item.flaggable.encrypted_flaggable_title,
        flag_count: item.flag_count,
        id: item.flaggable_id,
        pseudonym: item.flaggable.user.pseudonym,
        user_id: item.flaggable.user.id,
      }
    end

    return [flagged_items, relation]
  end
end
