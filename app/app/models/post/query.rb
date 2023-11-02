class Post::Query
  ALLOWED_ATTRIBUTES = {
    id: '',
    category: '',
    encrypted_body: '',
    encrypted_title: '',
    body: '',
    user_id: '',
    created_at: '',
    pseudonym: '',
    score: '',
    my_vote: '',
  }

  def self.build(params={}, initial_posts: nil)
    initial_posts ||= Post.all

    created_before_param = params[:created_before] || Upvote::FAR_FUTURE_TIME
    created_before = Time.at(created_before_param.to_f).utc

    posts = initial_posts
      .created_before(created_before)
      .joins(:user)
      .left_outer_joins_with_most_recent_upvotes_created_before(created_before)
      .page(params[:page])
      .group(:id, :pseudonym)
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
        ).gsub(/\s+/, ' '),
        cutoff_time: created_before,
        gravity: 1.5,
        time_division: 1.hour])))
    end

    posts
  end

  private

  def self.selections(params)
    score = 'COALESCE(SUM(value), 0) AS score'

    # Even though there is at most one most_recent_upvote per requester per
    # post, SUM is used because an aggregate function is required
    my_vote = Post.sanitize_sql_array([
      "SUM(CASE WHEN upvotes.user_id = :requester_id THEN value ELSE 0 END) AS my_vote",
      requester_id: params[:requester_id]])

    attributes = ALLOWED_ATTRIBUTES.merge(my_vote: my_vote, score: score)
    attributes.map { |k,v| (v.blank?) ? k : v }
  end
end
