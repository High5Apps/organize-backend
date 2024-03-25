class Api::V1::VotesController < ApplicationController
  PERMITTED_PARAMS = [
    candidate_ids: [],
  ]

  before_action :authenticate_user, only: [:create]
  before_action :check_ballot_belongs_to_org, only: [:create]

  def create
    vote = @ballot.votes.create_with(create_params)
      .find_or_create_by(user_id: authenticated_user.id)

    # update will no-op if vote was just created or candidate_ids was unchanged
    if vote.update(create_params)
      render json: { id: vote.id }, status: :created
    else
      render_error :unprocessable_entity, vote.errors.full_messages
    end
  end

  private

  def create_params
    params.require(:vote).permit(PERMITTED_PARAMS)
  end
end
