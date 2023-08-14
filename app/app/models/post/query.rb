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
      .order(created_at: :desc)
      .page(params[:page])
      .select(*ATTRIBUTE_ALLOW_LIST)

    posts
  end
end
