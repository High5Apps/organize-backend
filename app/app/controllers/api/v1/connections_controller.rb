class Api::V1::ConnectionsController < ApplicationController
  before_action :authenticate_user, only: [:create]
  before_action :authenticate_sharer, only: [:create, :preview]

  def create
    new_connection = authenticated_user.scanned_connections.build(
      sharer: @authenticated_sharer)
    if new_connection.save
      return render json: { id: new_connection.id }, status: :created
    end


    existing_connection = authenticated_user.connection_to @authenticated_sharer
    if existing_connection
      existing_connection.touch
      return render json: { id: existing_connection.id }, status: :ok
    end
      
    render json: {
      error_messages: new_connection.errors.full_messages
    }, status: :unprocessable_entity
  end

  # Note that this endpoint is unique in that it doesn't require requester
  # authentication, only sharer authentication. It needs to be called before new
  # users register, so it's not possible to require requester authentication.
  # However, it's still relatively safe, because it authenticates the sharer.
  def preview
    org = @authenticated_sharer.org
    if org
      render json: {
        org: {
          id: org.id,
          name: org.name,
          potential_member_definition: org.potential_member_definition,
        }, user: {
          pseudonym: @authenticated_sharer.pseudonym,
        }
      }
    else
      render_error :not_found, ["No org found for user #{@authenticated_sharer.id}"]
    end
  end

  private

  def authenticate_sharer
    @authenticated_sharer = authenticate(params[:sharer_jwt], 'create:connections')
    render_unauthorized unless @authenticated_sharer
  end
end
