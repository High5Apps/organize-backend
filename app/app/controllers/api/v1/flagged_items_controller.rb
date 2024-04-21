class Api::V1::FlaggedItemsController < ApplicationController
  PERMITTED_PARAMS = ['ballot_id', 'comment_id', 'post_id']

  before_action :authenticate_user, only: [:create]
  before_action :check_org_membership, only: [:create]
  before_action :check_flaggable_belongs_to_org, only: [:create]

  def create
    new_flagged_item = @flaggable.flagged_items.build(create_params)
    if new_flagged_item.save
      head :created
    else
      render_error :unprocessable_entity, new_flagged_item.errors.full_messages
    end
  end

  private

  def check_flaggable_belongs_to_org
    ballot_id = params[:ballot_id]
    comment_id = params[:comment_id]
    post_id = params[:post_id]
    item_ids = [ballot_id, comment_id, post_id]

    unless item_ids.compact.count == 1
      return render_error :bad_request, ["Must include exactly one item ID"]
    end

    if ballot_id
      @flaggable = @org.ballots.find_by id: ballot_id
    elsif comment_id
      @flaggable = @org.comments.find_by id: comment_id
    else
      @flaggable = @org.posts.find_by id: post_id
    end

    unless @flaggable
      render_error :not_found, ['Item not found']
    end
  end

  def create_params
    params.slice(PERMITTED_PARAMS)
      .permit(PERMITTED_PARAMS)
      .merge(user_id: authenticated_user.id)
  end
end
