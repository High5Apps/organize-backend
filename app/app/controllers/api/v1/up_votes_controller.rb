class Api::V1::UpVotesController < ApplicationController
  PERMITTED_PARAMS = [
    :value,
  ]

  before_action :authenticate_user, only: [:create]
  before_action :check_up_votable_belongs_to_org, only: [:create]

  def create
    new_up_vote = @up_votable.up_votes.build create_params
    if new_up_vote.save
      head :created
    else
      render_error :unprocessable_entity, new_up_vote.errors.full_messages
    end
  end

  private

  def check_up_votable_belongs_to_org
    post_id = params[:post_id]
    comment_id = params[:comment_id]

    unless post_id || comment_id
      return render_error :bad_request, ['Must include post_id or comment_id']
    end

    if post_id
      @up_votable = Post.find_by id: post_id
      post = @up_votable
    else
      @up_votable = Comment.includes(:post).find_by id: comment_id
      post = @up_votable&.post
    end

    unless post&.org == authenticated_user.org
      render_error :not_found, ['Up-votable not found']
    end
  end
  
  def create_params
    params.require(:up_vote)
      .permit(PERMITTED_PARAMS)
      .merge user_id: authenticated_user.id
  end
end
