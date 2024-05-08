class Api::V1::TermsController < ApplicationController
  before_action :authenticate_user, only: [:create]

  def create
    new_term = authenticated_user.terms.build create_params
    if new_term.save
      render json: { id: new_term.id }, status: :created
    else
      render_error :unprocessable_entity, new_term.errors.full_messages
    end
  end

  private

  def create_params
    params.require(:term)
      .permit(:accepted)
      .merge(ballot_id: params[:ballot_id])
  end
end
