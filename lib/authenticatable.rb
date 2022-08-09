module Authenticatable
  def authenticated_user
    return @authenticated_user if @authenticated_user

    header = request.headers['Authorization']
    return nil if header.nil?

    begin
      subject = JsonWebToken.unauthenticated_decode(header)[:sub]
      unauthenticated_user = User.find_by_id(subject)
      decoded = JsonWebToken.decode(header, unauthenticated_user.public_key)
    rescue JWT::DecodeError
      return nil
    end

    @authenticated_user = unauthenticated_user
  end
end
