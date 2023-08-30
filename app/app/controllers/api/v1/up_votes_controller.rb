class Api::V1::UpVotesController < ApplicationController
  PERMITTED_PARAMS = [
    :value,
  ]

  before_action :authenticate_user, only: [:create]
  before_action :check_up_votable_belongs_to_org, only: [:create]
  before_action :manually_validate_before_upsert, only: [:create]

  def create
    results = @up_votable.up_votes.upsert create_params,
      returning: Arel.sql('created_at, updated_at, CURRENT_TIMESTAMP as now'),
      unique_by: @unique_by_index
    result = results.to_a.first

    created_at, updated_at, now = \
      result.values_at 'created_at', 'updated_at', 'now'

    return head :not_modified unless updated_at == now

    if created_at == now
      head :created
    else
      head :ok
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
      @unique_by_index = :index_up_votes_on_post_id_and_user_id
      post = @up_votable
    else
      @up_votable = Comment.includes(:post).find_by id: comment_id
      @unique_by_index = :index_up_votes_on_comment_id_and_user_id
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

  # upsert skips validations, so need to manually validate before upserting
  # https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-upsert
  def manually_validate_before_upsert
    up_vote = @up_votable.up_votes.build create_params
    unless up_vote.valid?
      render_error :unprocessable_entity, up_vote.errors.full_messages
    end
  end
end
