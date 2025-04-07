class Post::Query
  ALLOWED_ATTRIBUTES = {
    id: '',
    candidate_id: '',
    category: '',
    deleted_at: '',
    encrypted_body: '',
    encrypted_title: '',
    user_id: '',
    created_at: '',
    pseudonym: 'users.pseudonym',
    score: '',
    my_vote: '',
  }

  def self.build(initial_posts, params={})
    return Post.none.page(params[:page]).without_count unless initial_posts

    now = Time.now

    created_at_or_before_param = params[:created_at_or_before] || now.iso8601(6)
    created_at_or_before = Time.iso8601(created_at_or_before_param.to_s).utc

    posts = initial_posts
      .created_at_or_before(created_at_or_before)
      .joins(:user)
      .with(upvotes: Upvote.created_at_or_before(created_at_or_before))
      .left_outer_joins(:upvotes)
      .page(params[:page]).without_count
      .group(:id, 'users.pseudonym')
      .select(*selections(params))

    category_parameter = params[:category]
    if category_parameter == 'general'
      posts = posts.general
    elsif category_parameter == 'grievances'
      posts = posts.grievances
    elsif category_parameter == 'demands'
      posts = posts.demands
    end

    # Default to sorting by new
    sort_parameter = params[:sort] || 'new'
    if sort_parameter == 'new'
      posts = posts.order(created_at: :desc, id: :desc)
    elsif sort_parameter == 'old'
      posts = posts.order(created_at: :asc, id: :asc)
    elsif sort_parameter == 'top'
      posts = posts.order(score: :desc, id: :desc)
    elsif sort_parameter == 'hot'
      posts = posts.order(Arel.sql(Post.sanitize_sql_array([
        %(
          (1 + COALESCE(SUM(value), 0)) /
          (2 +
            (EXTRACT(EPOCH FROM (:cutoff_time - posts.created_at)) /
            :time_division)
          )^:gravity DESC, posts.id DESC
        ).squish,
        cutoff_time: created_at_or_before,
        gravity: 0.975,
        time_division: 1.hour.to_i])))
    end

    posts
  end

  private

  def self.selections(params)
    score = 'COALESCE(SUM(value), 0) AS score'

    # Even though there is at most one upvote per requester per post, SUM is
    # needed because an aggregate function is required
    my_vote = Post.sanitize_sql_array([
      "SUM(CASE WHEN upvotes.user_id = :requester_id THEN value ELSE 0 END) AS my_vote",
      requester_id: params[:requester_id]])

    attributes = ALLOWED_ATTRIBUTES.merge(my_vote:, score:)
    attributes.map { |k,v| (v.blank?) ? k : v }
  end
end
