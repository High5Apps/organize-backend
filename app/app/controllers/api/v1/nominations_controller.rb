class Api::V1::NominationsController < ApplicationController
  PERMITTED_PARAMS = [
    :nominee_id,
  ]

  before_action :authenticate_user, only: [:create]
  before_action :check_ballot_belongs_to_org, only: [:create]

  def create
    new_nomination = @ballot.nominations.build create_params
    if new_nomination.save
      render json: { id: new_nomination.id }, status: :created
    else
      render_error :unprocessable_entity, new_nomination.errors.full_messages
    end
  end

  private

  def create_params
    params.require(:nomination)
      .permit(PERMITTED_PARAMS)
      .merge(nominator_id: authenticated_user.id)
  end
end
