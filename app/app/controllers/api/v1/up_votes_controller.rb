class Api::V1::UpVotesController < ApplicationController
  PERMITTED_PARAMS = [
    :value,
  ]

  before_action :authenticate_user, only: [:create, :update]
  before_action :check_commentable_belongs_to_org, only: [:create]
  before_action :check_up_vote_belongs_to_user, only: [:update]

  def create
    params_with_user_id = create_params.merge user_id: authenticated_user.id
    new_up_vote = @commentable.up_votes.build params_with_user_id
    if new_up_vote.save
      render json: { id: new_up_vote.id }, status: :created
    else
      render_error :unprocessable_entity, new_up_vote.errors.full_messages
    end
  end

  def update
    if @up_vote.update update_params
      head :no_content
    else
      render_error :unprocessable_entity, @up_vote.errors.full_messages
    end
  end

  private

  def check_commentable_belongs_to_org
    post_id = params[:post_id]
    comment_id = params[:comment_id]

    unless post_id || comment_id
      return render_error :bad_request, ['Must include post_id or comment_id']
    end

    if post_id
      @commentable = Post.find_by id: post_id
      post = @commentable
    else
      @commentable = Comment.includes(:post).find_by id: comment_id
      post = @commentable&.post
    end

    unless post&.org == authenticated_user.org
      render_error :not_found, ['Up-votable not found']
    end
  end
  
  def create_params
    params.require(:up_vote).permit(PERMITTED_PARAMS)
  end

  def check_up_vote_belongs_to_user
    @up_vote = authenticated_user.up_votes.find_by id: params[:id]
    unless @up_vote
      render_error :not_found, ['Up vote not found']
    end
  end

  def update_params
    params.require(:up_vote).permit(PERMITTED_PARAMS)
  end
end
