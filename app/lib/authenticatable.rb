module Authenticatable
  HEADER_AUTHORIZATION = 'Authorization'.freeze
  HEADER_SHARER_AUTHORIZATION = 'Sharer-Authorization'.freeze
  SCOPE_CREATE_CONNECTIONS = 'create:connections'.freeze
  SCOPE_ALL = '*'.freeze

  class AuthenticationError < StandardError; end
  class AuthorizationError < StandardError; end

  def authenticated_user
    return @authenticated_user if @authenticated_user

    @authenticated_user = authenticate scope: SCOPE_ALL
  end

  def authenticate(scope:, header: HEADER_AUTHORIZATION)
    jwt = auth_token(header)
    user_id = unauthenticated_user_id(jwt)
    user = User.find_by_id(user_id)
    raise AuthenticationError unless user

    begin
      valid_jwt = JsonWebToken.decode(jwt, user.public_key)
    rescue => error
      logger.error error
      raise AuthenticationError
    end

    raise AuthorizationError unless authorize(valid_jwt, scope)

    user
  end

  private

  def auth_token(header_name)
    auth_header = request.headers[header_name]
    auth_header&.start_with?('Bearer ') ? auth_header[7..] : nil
  end

  def authorize(jwt, scope)
    [scope, SCOPE_ALL].include? jwt[:scp]
  end

  def unauthenticated_user_id(jwt)
    begin
      JsonWebToken.unauthenticated_decode(jwt)[:sub]
    rescue JWT::DecodeError => error
      logger.error error
      nil
    end
  end
end
