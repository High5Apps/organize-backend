class Api::V1::CandidatesController < ApplicationController
  ALLOWED_ATTRIBUTES = [
    :id,
    :encrypted_title,
  ]

  before_action :authenticate_user, only: [:index]
  before_action :check_org_membership, only: [:index]

  def index
    ballot = @org.ballots.find_by(id: params[:ballot_id])
    return head :not_found unless ballot

    candidates = ballot.candidates.select(ALLOWED_ATTRIBUTES)
    render json: { candidates: candidates }
  end
end
