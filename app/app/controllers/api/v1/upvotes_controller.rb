class Api::V1::UpvotesController < ApplicationController
  PERMITTED_PARAMS = [
    :value,
  ]

  before_action :authenticate_user, only: [:create]
  before_action :check_upvotable_belongs_to_org, only: [:create]

  def create
    upvote = @upvotable.upvotes.create_with(create_params)
      .create_or_find_by(user_id: authenticated_user.id)

    # update will no-op in the usual case where upvote didn't already exist
    # update will hit the database when upvote already existed and value changed
    if upvote.update(create_params)
      head :created
    else
      render_error :unprocessable_entity, upvote.errors.full_messages
    end
  end

  private

  def check_upvotable_belongs_to_org
    post_id = params[:post_id]
    comment_id = params[:comment_id]

    unless post_id || comment_id
      return render_error :bad_request, ['Must include post_id or comment_id']
    end

    if post_id
      @upvotable = Post.find_by id: post_id
      post = @upvotable
    else
      @upvotable = Comment.includes(:post).find_by id: comment_id
      post = @upvotable&.post
    end

    unless post&.org == authenticated_user.org
      render_error :not_found, ['Up-votable not found']
    end
  end

  def create_params
    params.require(:upvote).permit(PERMITTED_PARAMS)
  end
end
