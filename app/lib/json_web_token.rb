class JsonWebToken
  def self.encode(payload, private_key)
    JWT.encode payload, private_key, 'RS256'
  end

  def self.decode(token, public_key)
    options = { required_claims: ['exp', 'scp', 'sub'], algorithm: 'RS256' }
    decoded = JWT.decode(token, public_key, true, options).first
    HashWithIndifferentAccess.new decoded
  end

  def self.payload(subject, expiration, scope)
    payload = {}
    payload.store(:sub, subject) if subject
    payload.store(:exp, expiration.to_i) if expiration
    payload.store(:scp, scope) if scope
    payload
  end

  def self.unauthenticated_decode(token)
    decoded = JWT.decode(token, nil, false).first
    HashWithIndifferentAccess.new decoded
  end
end
