class Api::V1::CommentsController < ApplicationController
  PERMITTED_PARAMS = [
    :body,
    :post_id,
  ]

  before_action :authenticate_user, only: [:create]
  before_action :check_post_belongs_to_org, only: [:create]

  def create
    new_comment = authenticated_user.comments.build create_params
    if new_comment.save
      render json: { id: new_comment.id }, status: :created
    else
      render_error :unprocessable_entity, new_comment.errors.full_messages
    end
  end

  private

  def check_post_belongs_to_org
    post = Post.find_by id: params[:comment][:post_id]
    unless post&.org == authenticated_user.org
      render_error :not_found, ['Post not found']
    end
  end

  def create_params
    params.require(:comment).permit(PERMITTED_PARAMS)
  end
end
