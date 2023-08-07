class Api::V1::PostsController < ApplicationController
  PERMITTED_PARAMS = [
    :body,
    :category,
    :title,
  ]

  INDEX_ATTRIBUTE_ALLOW_LIST = [
    :id,
    :category,
    :title,
    :body,
    :user_id,
    :created_at,
  ]

  before_action :authenticate_user, only: [:index, :create]
  before_action :check_org_membership, only: [:index, :create]

  def create
    new_post = authenticated_user.posts.build(create_params.merge(org: @org))
    if new_post.save
      render json: { id: new_post.id }, status: :created
    else
      render_error :unprocessable_entity, new_post.errors.full_messages
    end
  end

  def index
    posts = @org.posts.order created_at: :desc
    render json: {
      posts: posts.as_json(only: INDEX_ATTRIBUTE_ALLOW_LIST),
    }
  end

  private

  def create_params
    params.require(:post).permit(PERMITTED_PARAMS)
  end

  def check_org_membership
    @org = authenticated_user.org
    unless @org
      render_error :not_found, ['You must join an Org first']
    end
  end
end
