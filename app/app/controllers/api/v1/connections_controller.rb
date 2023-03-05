class Api::V1::ConnectionsController < ApplicationController
  before_action :authenticate_user, only: [:create]
  before_action :authenticate_sharer, only: [:create]

  def create
    new_connection = authenticated_user.scanned_connections.build(
      sharer: @authenticated_sharer)
    if new_connection.save
      return render json: { id: new_connection.id }, status: :created
    end

    existing_connection = authenticated_user.scanned_connections.where(
      sharer: @authenticated_sharer).first
    if existing_connection
      existing_connection.touch
      return render json: { id: existing_connection.id }, status: :ok
    end
      
    render json: {
      error_messages: new_connection.errors.full_messages
    }, status: :unprocessable_entity
  end

  private

  def authenticate_sharer
    @authenticated_sharer = authenticate(params[:sharer_jwt], 'create:connections')
    render_unauthorized unless @authenticated_sharer
  end
end
