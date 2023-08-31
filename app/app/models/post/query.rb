class Post::Query
  ATTRIBUTE_ALLOW_LIST = [
    :id,
    :category,
    :title,
    :body,
    :user_id,
    :created_at,
    :pseudonym,
  ]

  def self.build(params={}, initial_posts: nil)
    initial_posts ||= Post.all

    posts = initial_posts
      .joins(:user)
      .page(params[:page])
      .select(*ATTRIBUTE_ALLOW_LIST)

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

    created_before_param = params[:created_before]
    if created_before_param
      created_before = Time.at(created_before_param.to_f).utc
      posts = posts.created_before(created_before)
    end

    # Default to sorting by new
    sort_parameter = params[:sort] || 'new'
    if sort_parameter == 'new'
      posts = posts.order(created_at: :desc)
    elsif  sort_parameter == 'old'
      posts = posts.order(created_at: :asc)
    end

    posts
  end
end
