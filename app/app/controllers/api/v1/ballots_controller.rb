class Api::V1::BallotsController < ApplicationController
  ALLOWED_ATTRIBUTES = [
    :ballot,
    :candidates,
    :my_vote,
    :results,
  ]
  ALLOWED_BALLOT_ATTRIBUTES = Ballot::Query::ALLOWED_ATTRIBUTES + [
    :max_candidate_ids_per_vote,
  ]
  ALLOWED_CANDIDATE_ATTRIBUTES = [:encrypted_title, :id]
  MAX_CANDIDATES_PER_CREATE = 100.freeze

  before_action :authenticate_user, only: [:index, :create, :show]
  before_action :check_org_membership, only: [:index, :create, :show]
  before_action :validate_election, only: [:create]
  before_action :validate_multiple_choice, only: [:create]
  before_action :validate_yes_no, only: [:create]

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
      ballots:,
      meta: (pagination_dict(ballots) if params[:page]),
    }.compact
  end

  def show
    ballot = @org.ballots.find_by(id: params[:id])

    unless ballot
      return render_error :not_found, ["No ballot found with id #{params[:id]}"]
    end

    render json: {
      ballot: ballot.slice(ALLOWED_BALLOT_ATTRIBUTES),
      candidates: ballot.candidates.select(ALLOWED_CANDIDATE_ATTRIBUTES),
      my_vote: authenticated_user.my_vote_candidate_ids(ballot),
      results: (ballot.results unless Time.now < ballot.voting_ends_at),
  }.compact
  end

  private

  def create_ballot_params
    params.require(:ballot)
      .permit(
        :category,
        :max_candidate_ids_per_vote,
        :office,
        :nominations_end_at,
        :term_ends_at,
        EncryptedMessage.permitted_params(:question),
        :voting_ends_at)
  end

  def create_candidates_params
    return [] unless params[:candidates]&.any?
    params.slice(:candidates)
      .permit(candidates: [EncryptedMessage.permitted_params(:title)])
      .require(:candidates)
  end

  def validate_election
    return unless create_ballot_params[:category] == 'election'

    unless create_candidates_params.count == 0
      return render_error :unprocessable_entity,
        ['Election candidates must be created via nominations']
    end
  end

  def validate_multiple_choice
    return unless create_ballot_params[:category] == 'multiple_choice'

    candidate_count = create_candidates_params.count
    unless candidate_count >= 2
      return render_error :unprocessable_entity,
        ['Multiple choice ballots must have at least 2 unique choices']
    end

    unless candidate_count <= MAX_CANDIDATES_PER_CREATE
      return render_error :unprocessable_entity,
        ["Multiple choice ballots can't have more than #{MAX_CANDIDATES_PER_CREATE} choices"]
    end

    max_candidate_ids_per_vote = \
      create_ballot_params[:max_candidate_ids_per_vote].to_i || 1
    unless max_candidate_ids_per_vote <= candidate_count
      return render_error :unprocessable_entity,
        ["Max selections can't be more than the number of unique choices"]
    end
  end

  def validate_yes_no
    return unless create_ballot_params[:category] == 'yes_no'

    unless create_candidates_params.count == 2
      render_error :unprocessable_entity, ['Yes/No ballots must have 2 choices']
    end
  end
end
