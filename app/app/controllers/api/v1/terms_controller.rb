class Api::V1::TermsController < ApplicationController
  before_action :authenticate_user, only: [:create]
  before_action :check_ballot_belongs_to_org, only: [:create]

  def create
    new_term = @ballot.terms.build create_params
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
      .merge ends_at: @ballot.term_ends_at,
        office: @ballot.office,
        starts_at: @ballot.term_starts_at,
        user: authenticated_user
  end
end
