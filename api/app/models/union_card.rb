class UnionCard < ApplicationRecord
  include Encryptable

  MAX_AGREEMENT_LENGTH = \
    93 + Org::MAX_NAME_LENGTH + Org::MAX_EMPLOYER_NAME_LENGTH
  MAX_EMAIL_LENGTH = Org::MAX_EMAIL_LENGTH
  MAX_EMPLOYER_NAME_LENGTH = Org::MAX_EMPLOYER_NAME_LENGTH
  MAX_NAME_LENGTH = 100
  MAX_PHONE_LENGTH = 20
  SIGNATURE_LENGTH = 88

  belongs_to :user

  has_one :org, through: :user

  validates :signature_bytes,
    presence: true,
    length: { is: SIGNATURE_LENGTH }
  validates :signed_at, presence: true
  validates :user, uniqueness: true

  has_encrypted :agreement, present: true, max_length: MAX_AGREEMENT_LENGTH
  has_encrypted :email, present: true, max_length: MAX_EMAIL_LENGTH
  has_encrypted :employer_name,
    present: true,
    max_length: MAX_EMPLOYER_NAME_LENGTH
  has_encrypted :name, present: true, max_length: MAX_NAME_LENGTH
  has_encrypted :phone, present: true, max_length: MAX_PHONE_LENGTH

  # This should only be used when joined with user
  def public_key_bytes
    begin
      OpenSSL::PKey::EC.new(attributes['public_key_bytes']).to_pem
    rescue
      nil
    end
  end

  def signature_bytes=(value)
    begin
      write_attribute :signature_bytes, Base64.strict_decode64(value)
    rescue
      write_attribute :signature_bytes, nil
    end
  end

  def signature_bytes
    begin
      Base64.strict_encode64 attributes['signature_bytes']
    rescue
      nil
    end
  end
end
