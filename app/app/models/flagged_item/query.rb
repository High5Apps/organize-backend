class FlaggedItem::Query
  def self.build(params={}, initial_flagged_items: nil)
    initial_flagged_items ||= FlaggedItem.all

    now = Time.now

    created_at_or_before_param = params[:created_at_or_before] || now
    created_at_or_before = Time.parse(created_at_or_before_param.to_s).utc

    flagged_items = FlaggedItem.with(groups: initial_flagged_items
    .created_at_or_before(created_at_or_before)
      .select(:ballot_id, :comment_id, :post_id, 'COUNT(*) AS flag_count')
      .group(:ballot_id, :comment_id, :post_id)
      .having('COALESCE(ballot_id, comment_id, post_id) IS NOT NULL')
    ).from('groups AS flagged_items')
      .left_joins(ballot: :user, comment: :user, post: :user)
      .select(
        :ballot_id, :comment_id, :post_id, :flag_count,
        'COALESCE(users.id, users_comments.id, users_posts.id) AS user_id',
        'COALESCE(users.pseudonym, users_comments.pseudonym, users_posts.pseudonym) AS pseudonym',
        'COALESCE(ballots.encrypted_question, comments.encrypted_body, posts.encrypted_title) AS title'
      )

    # Default to sorting by top
    sort_parameter = params[:sort] || 'top'
    if sort_parameter == 'top'
      flagged_items = flagged_items.order('flag_count DESC, user_id DESC')
    end

    flagged_items
  end
end
