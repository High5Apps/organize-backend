class JsonWebToken
  def self.encode(payload, private_key)
    JWT.encode payload, private_key, 'RS256'
  end

  def self.decode(token, public_key)
    options = { required_claims: ['exp'], algorithm: 'RS256' }
    decoded = JWT.decode(token, public_key, true, options).first
    HashWithIndifferentAccess.new decoded
  end

  def self.payload(subject, expiration)
    payload = {}

    if subject
      payload[:sub] = subject
    end

    if expiration
      payload[:exp] = expiration.to_i
    end

    payload
  end

  def self.unauthenticated_decode(token)
    decoded = JWT.decode(token, nil, false).first
    HashWithIndifferentAccess.new decoded
  end
end
