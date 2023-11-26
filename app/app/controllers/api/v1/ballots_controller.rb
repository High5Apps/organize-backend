class Api::V1::BallotsController < ApplicationController
  ALLOWED_BALLOT_ATTRIBUTES = Ballot::Query::ALLOWED_ATTRIBUTES + [
    :max_candidate_ids_per_vote,
  ]
  ALLOWED_CANDIDATE_ATTRIBUTES = [:encrypted_title, :id]
  MAX_CANDIDATES_PER_CREATE = 100.freeze

  before_action :authenticate_user, only: [:index, :create, :show]
  before_action :check_org_membership, only: [:index, :create, :show]
  before_action :limit_candidate_count, only: [:create]

  def create
    begin
      new_ballot = nil

      ActiveRecord::Base.transaction do
        new_ballot = authenticated_user.ballots.create! create_ballot_params

        create_candidates_params.each do |create_params|
          candidate = new_ballot.candidates.create! create_params
        end
      end
    rescue ActiveRecord::RecordInvalid => invalid
      render_error :unprocessable_entity, invalid.record.errors.full_messages
    else
      render json: { id: new_ballot.id }, status: :created
    end
  end

  def index
    ballots = Ballot::Query.build params,
      initial_ballots: authenticated_user.org.ballots
    render json: {
      ballots: ballots,
      meta: (pagination_dict(ballots) if params[:page]),
    }.compact
  end

  def show
    ballot = @org.ballots.find_by(id: params[:id])

    unless ballot
      return render_error :not_found, ["No ballot found with id #{params[:id]}"]
    end

    candidates = ballot.candidates.select(ALLOWED_CANDIDATE_ATTRIBUTES)

    render json: {
      ballot: ballot.slice(ALLOWED_BALLOT_ATTRIBUTES),
      candidates: candidates,
    }
  end

  private

  def create_ballot_params
    params.require(:ballot)
      .permit(
        :category,
        EncryptedMessage.permitted_params(:question),
        :voting_ends_at)
  end

  def create_candidates_params
    return [] unless params.has_key? :candidates
    params.slice(:candidates)
      .permit(candidates: [EncryptedMessage.permitted_params(:title)])
      .require(:candidates)
  end

  def limit_candidate_count
    if create_candidates_params.count > MAX_CANDIDATES_PER_CREATE
      render_error :unprocessable_entity,
        ["Ballot can't have more than #{MAX_CANDIDATES_PER_CREATE} candidates"]
    end
  end
end
