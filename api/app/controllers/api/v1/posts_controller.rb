class Api::V1::PostsController < ApplicationController
  PERMITTED_PARAMS = [
    :candidate_id,
    :category,
    EncryptedMessage.permitted_params(:body),
    EncryptedMessage.permitted_params(:title),
  ]

  def create
    new_post = authenticated_user.posts.build create_params
    if new_post.save
      render json: { id: new_post.id, created_at: new_post.created_at },
        status: :created
    else
      render_error :unprocessable_entity, new_post.errors.full_messages
    end
  end

  def index
    initial_posts = authenticated_user.org&.posts&.omit_blocked
    posts = Post::Query.build initial_posts, query_params
    render json: { posts:, meta: pagination_dict(posts) }
  end

  def show
    initial_posts = authenticated_user.org&.posts
    post = Post::Query.build(initial_posts, query_params).find params[:id]
    render json: { post: }
  end

  private

  def create_params
    params.require(:post).permit(PERMITTED_PARAMS)
  end

  def query_params
    params.merge requester_id: authenticated_user.id
  end
end
