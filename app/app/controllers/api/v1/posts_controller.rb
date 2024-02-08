class Api::V1::PostsController < ApplicationController
  PERMITTED_PARAMS = [
    :body,
    :category,
    EncryptedMessage.permitted_params(:body),
    EncryptedMessage.permitted_params(:title),
  ]

  before_action :authenticate_user, only: [:index, :create]
  before_action :check_org_membership, only: [:index, :create]

  def create
    new_post = authenticated_user.posts.build(create_params.merge(org: @org))
    if new_post.save
      render json: { id: new_post.id, created_at: new_post.created_at },
        status: :created
    else
      render_error :unprocessable_entity, new_post.errors.full_messages
    end
  end

  def index
    posts = Post::Query.build query_params, initial_posts: @org.posts
    render json: { posts:, meta: pagination_dict(posts) }
  end

  private

  def create_params
    params.require(:post).permit(PERMITTED_PARAMS)
  end

  def query_params
    params.merge requester_id: authenticated_user.id
  end
end
