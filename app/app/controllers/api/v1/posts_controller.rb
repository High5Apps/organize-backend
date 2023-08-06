class Api::V1::PostsController < ApplicationController
  PERMITTED_PARAMS = [
    :body,
    :category,
    :title,
  ]

  before_action :authenticate_user, only: [:create]

  def create
    org = authenticated_user.org
    unless org
      return render_error :not_found,
        ['You must join an Org before you can create posts']
    end

    new_post = authenticated_user.posts.build(create_params.merge(org: org))
    if new_post.save
      render json: { id: new_post.id }, status: :created
    else
      render_error :unprocessable_entity, new_post.errors.full_messages
    end
  end

  private

  def create_params
    params.require(:post).permit(PERMITTED_PARAMS)
  end
end
