class Api::V1::NominationsController < ApplicationController
  PERMITTED_CREATE_PARAMS = [
    :nominee_id,
  ]
  PERMITTED_UPDATE_PARAMS = [
    :accepted
  ]

  before_action :authenticate_user, only: [:create, :update]
  before_action :check_ballot_belongs_to_org, only: [:create]
  before_action :check_received_nomination, only: [:update]

  def create
    new_nomination = @ballot.nominations.build create_params
    if new_nomination.save
      render json: { id: new_nomination.id }, status: :created
    else
      render_error :unprocessable_entity, new_nomination.errors.full_messages
    end
  end

  def update
    if @nomination.update(update_params)
      render json: {
        nomination: @nomination.slice(:id, *PERMITTED_UPDATE_PARAMS),
      }
    else
      render_error :unprocessable_entity, new_nomination.errors.full_messages
    end
  end

  private

  def check_received_nomination
    @nomination = authenticated_user.received_nominations
      .find_by id: params[:id]
    unless @nomination
      render_error :not_found, ['Nomination not found']
    end
  end

  def create_params
    params.require(:nomination)
      .permit(PERMITTED_CREATE_PARAMS)
      .merge(nominator_id: authenticated_user.id)
  end

  def update_params
    params.require(:nomination).permit(PERMITTED_UPDATE_PARAMS)
  end
end
