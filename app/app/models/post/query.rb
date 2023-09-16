class Post::Query
  ALLOWED_ATTRIBUTES = {
    id: '',
    category: '',
    title: '',
    body: '',
    user_id: '',
    created_at: '',
    pseudonym: '',
    score: '',
    my_vote: '',
  }

  def self.build(params={}, initial_posts: nil)
    initial_posts ||= Post.all

    created_before_param = params[:created_before] || UpVote::FAR_FUTURE_TIME
    created_before = Time.at(created_before_param.to_f).utc

    posts = initial_posts
      .created_before(created_before)
      .joins(:user)
      .joins(%Q(
        LEFT OUTER JOIN (
          #{UpVote.most_recent_created_before(created_before).to_sql}
        ) AS up_votes
          ON up_votes.post_id = posts.id
      ).gsub(/\s+/, ' '))
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

    created_after_param = params[:created_after]
    if created_after_param
      created_after = Time.at(created_after_param.to_f).utc
      posts = posts.created_after(created_after)
    end

    # Default to sorting by new
    sort_parameter = params[:sort] || 'new'
    if sort_parameter == 'new'
      posts = posts.order(created_at: :desc, id: :desc)
    elsif sort_parameter == 'old'
      posts = posts.order(created_at: :asc, id: :asc)
    elsif sort_parameter == 'top'
      posts = posts.order(score: :desc, id: :desc)
    end

    posts
  end

  private

  def self.selections(params)
    score = 'COALESCE(SUM(value), 0) AS score'

    # Even though there is at most one most_recent_upvote per requester per
    # post, SUM is used because an aggregate function is required
    my_vote = Post.sanitize_sql_array([
      "SUM(CASE WHEN up_votes.user_id = :requester_id THEN value ELSE 0 END) AS my_vote",
      requester_id: params[:requester_id]])

    attributes = ALLOWED_ATTRIBUTES.merge(my_vote: my_vote, score: score)
    attributes.map { |k,v| (v.blank?) ? k : v }
  end
end
