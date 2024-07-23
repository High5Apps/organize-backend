class Api::V1::VotesController < ApplicationController
  PERMITTED_PARAMS = [
    candidate_ids: [],
  ]

  def create
    vote = authenticated_user.votes.create_with(create_params)
      .find_or_create_by(ballot_id: params[:ballot_id])

    # update will no-op if vote was just created or candidate_ids was unchanged
    if vote.update(create_params)
      render json: { id: vote.id }, status: :created
    else
      render_error :unprocessable_entity, vote.errors.full_messages
    end
  end

  private

  def create_params
    params.require(:vote)
      .permit(PERMITTED_PARAMS)
      .merge(ballot_id: params[:ballot_id])
  end
end
