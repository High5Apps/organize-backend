class Api::V1::BallotsController < ApplicationController
  ALLOWED_ATTRIBUTES = [
    :ballot,
    :candidates,
    :my_vote,
    :nominations,
    :refreshed_at,
    :results,
    :terms,
  ]
  ALLOWED_BALLOT_ATTRIBUTES = Ballot::Query::ALLOWED_ATTRIBUTES + [
    :max_candidate_ids_per_vote,
  ]
  ALLOWED_BALLOT_ELECTION_ATTRIBUTES = ALLOWED_BALLOT_ATTRIBUTES + [
    :term_ends_at,
    :term_starts_at,
  ]
  ALLOWED_CANDIDATE_ATTRIBUTES = [:id]
  ALLOWED_ELECTION_CANDIDATE_ATTRIBUTES = ALLOWED_CANDIDATE_ATTRIBUTES + [
    :post_id,
    :user_id,
  ]
  ALLOWED_NON_ELECTION_CANDIDATE_ATTRIBUTES = \
    ALLOWED_CANDIDATE_ATTRIBUTES + [:encrypted_title]
  ALLOWED_NOMINATION_ATTRIBUTES = [
    :accepted,
    :id,
    :nominator,
    :nominee,
  ]
  ALLOWED_NOMINATION_USER_ATTRIBUTES = [
    :id,
    :pseudonym,
  ]
  ALLOWED_RESULTS_ATTRIBUTES = [
    :candidate_id,
    :rank,
    :vote_count,
  ]
  ALLOWED_TERMS_ATTRIBUTES = [
    :accepted,
    :user_id,
  ]
  MAX_CANDIDATES_PER_CREATE = 100.freeze

  before_action :authenticate_user, only: [:index, :create, :show]
  before_action :check_can_create_elections, :validate_election,
    only: [:create],
    if: -> { will_create 'election' }
  before_action :validate_multiple_choice, only: [:create],
    if: -> {  will_create 'multiple_choice' }
  before_action :validate_yes_no, only: [:create],
    if: -> { will_create 'yes_no' }

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
    ballots = Ballot::Query.build authenticated_user.org&.ballots, params
    render json: {
      ballots:,
      meta: (pagination_dict(ballots) if params[:page]),
    }.compact
  end

  def show
    @ballot = authenticated_user.org&.ballots&.find params[:id]
    return render_not_found unless @ballot

    render json: {
      ballot:,
      candidates:,
      my_vote:,
      nominations:,
      refreshed_at: Time.now.utc,
      results:,
      terms:,
    }.compact
  end

  private

  def ballot
    ballot_attributes = @ballot.election? ?
      ALLOWED_BALLOT_ELECTION_ATTRIBUTES :
      ALLOWED_BALLOT_ATTRIBUTES
    @ballot.slice(ballot_attributes)
  end

  def candidates
    relation = @ballot.candidates
    if @ballot.election?
      relation.left_outer_joins(:post, :user)
        .select(
          ALLOWED_ELECTION_CANDIDATE_ATTRIBUTES - [:post_id],
          'posts.id AS post_id')
    else
      relation.select(ALLOWED_NON_ELECTION_CANDIDATE_ATTRIBUTES)
    end
  end

  def create_ballot_params
    params.require(:ballot)
      .permit(
        :category,
        :max_candidate_ids_per_vote,
        :office,
        :nominations_end_at,
        :term_ends_at,
        :term_starts_at,
        EncryptedMessage.permitted_params(:question),
        :voting_ends_at)
  end

  def create_candidates_params
    return [] unless params[:candidates]&.any?
    params.slice(:candidates)
      .permit(candidates: [EncryptedMessage.permitted_params(:title)])
      .require(:candidates)
  end

  def will_create(category)
    create_ballot_params[:category] == category
  end

  def my_vote
    authenticated_user.my_vote_candidate_ids(@ballot)
  end

  def nominations
    return nil unless @ballot.election?

    allowed_user_attributes = ALLOWED_NOMINATION_USER_ATTRIBUTES
    @ballot.nominations.includes(:nominator, :nominee).map do |nomination|
      nomination.slice(ALLOWED_NOMINATION_ATTRIBUTES).merge({
        nominator: nomination.nominator.slice(allowed_user_attributes),
        nominee: nomination.nominee.slice(allowed_user_attributes),
      })
    end
  end

  def results
    return nil unless @ballot.voting_ended?
    @ballot.results
  end

  def terms
    return nil unless @ballot.election? && @ballot.voting_ended?
    @ballot.terms.select(ALLOWED_TERMS_ATTRIBUTES).as_json except: :id
  end

  def validate_election
    unless create_candidates_params.count == 0
      return render_error :unprocessable_entity,
        ['Election candidates must be created via nominations']
    end
  end

  def validate_multiple_choice
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
    unless create_candidates_params.count == 2
      render_error :unprocessable_entity, ['Yes/No ballots must have 2 choices']
    end
  end
end
