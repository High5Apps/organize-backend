class Api::V1::ConnectionsController < ApplicationController
  before_action :authenticate_sharer, only: [:create, :preview]
  skip_before_action :authenticate_user, only: :preview

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
          encrypted_name: org.encrypted_name,
          encrypted_member_definition: org.encrypted_member_definition,
          id: org.id,
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
    begin
      @authenticated_sharer = authenticate(
        scope: Authenticatable::SCOPE_CREATE_CONNECTIONS,
        header: Authenticatable::HEADER_SHARER_AUTHORIZATION)
    rescue Authenticatable::AuthorizationError
      render_unauthorized
    rescue
      render_unauthenticated
    end
  end
end
