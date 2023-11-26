class Api::V1::VotesController < ApplicationController
  PERMITTED_PARAMS = [
    candidate_ids: [],
  ]

  before_action :authenticate_user, only: [:create]
  before_action :check_ballot_belongs_to_org, only: [:create]

  def create
    new_vote = @ballot.votes.build create_params
    if new_vote.save
      render json: { id: new_vote.id }, status: :created
    else
      render_error :unprocessable_entity, new_vote.errors.full_messages
    end
  end

  private

  def create_params
    params.require(:vote)
      .permit(PERMITTED_PARAMS)
      .merge(user_id: authenticated_user.id)
  end

  def check_ballot_belongs_to_org
    @org = authenticated_user.org
    @ballot = @org&.ballots&.find_by id: params[:ballot_id]
    unless @org && @ballot && (@org == @ballot.org)
      render_error :not_found, ['Ballot not found']
    end
  end
end
