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

  def self.build(params, initial_posts: nil)
    initial_posts ||= Post.all

    posts = initial_posts
      .joins(:user)
      .page(params[:page])
      .select(*ATTRIBUTE_ALLOW_LIST)

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
