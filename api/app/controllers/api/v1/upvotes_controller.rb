class Api::V1::UpvotesController < ApplicationController
  PERMITTED_PARAMS = [
    :value,
  ]

  def create
    comment_id = params[:comment_id]
    post_id = params[:post_id]
    upvote = authenticated_user.upvotes.create_with(create_params)
      .create_or_find_by(comment_id:, post_id:)

    # update will no-op in the usual case where upvote didn't already exist
    # update will hit the database when upvote already existed and value changed
    if upvote.update(create_params)
      head :created
    else
      render_error :unprocessable_entity, upvote.errors.full_messages
    end
  end

  private

  def create_params
    params.require(:upvote)
      .permit(PERMITTED_PARAMS)
      .merge({
        comment_id: params[:comment_id],
        post_id: params[:post_id],
      })
  end
end
