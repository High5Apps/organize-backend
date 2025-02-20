class UnionCard < ApplicationRecord
  include Encryptable

  MAX_AGREEMENT_LENGTH = \
    93 + Org::MAX_NAME_LENGTH + Org::MAX_EMPLOYER_NAME_LENGTH
  MAX_EMAIL_LENGTH = Org::MAX_EMAIL_LENGTH
  MAX_EMPLOYER_NAME_LENGTH = Org::MAX_EMPLOYER_NAME_LENGTH
  MAX_NAME_LENGTH = 100
  MAX_PHONE_LENGTH = 20
  SIGNATURE_LENGTH = 61

  belongs_to :user

  validates :signature_bytes,
    presence: true,
    length: { is: SIGNATURE_LENGTH }
  validates :signed_at, presence: true

  has_encrypted :agreement, present: true, max_length: MAX_AGREEMENT_LENGTH
  has_encrypted :email, present: true, max_length: MAX_EMAIL_LENGTH
  has_encrypted :employer_name,
    present: true,
    max_length: MAX_EMPLOYER_NAME_LENGTH
  has_encrypted :name, present: true, max_length: MAX_NAME_LENGTH
  has_encrypted :phone, present: true, max_length: MAX_PHONE_LENGTH
end
