class Api::V1::BallotsController < ApplicationController
  MAX_CANDIDATES_PER_CREATE = 100.freeze

  before_action :authenticate_user, only: [:create]
  before_action :limit_candidate_count, only: [:create]

  def create
    begin
      new_ballot = nil

      ActiveRecord::Base.transaction do
        new_ballot = authenticated_user.org.ballots.create! create_ballot_params

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

  private

  def create_ballot_params
    params.require(:ballot).permit(
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
