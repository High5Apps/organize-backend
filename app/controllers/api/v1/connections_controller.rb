class Api::V1::ConnectionsController < ApplicationController
  before_action :authenticate_user, only: [:create]
  before_action :authenticate_sharer, only: [:create]

  def create
    new_connection = authenticated_user.scanned_connections.build(
      sharer: @authenticated_sharer)
    if new_connection.save
      render json: { id: new_connection.id }, status: :created
    else
      render json: {
        error_messages: new_connection.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def authenticate_sharer
    @authenticated_sharer = authenticate(params[:sharer_jwt])
    render_unauthorized unless @authenticated_sharer
  end
end
