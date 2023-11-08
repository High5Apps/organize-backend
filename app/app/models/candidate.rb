class Candidate < ApplicationRecord
  include Encryptable

  MAX_TITLE_LENGTH = 30

  belongs_to :ballot

  validates :ballot, presence: true

  has_encrypted :title, present: true, max_length: MAX_TITLE_LENGTH
end
