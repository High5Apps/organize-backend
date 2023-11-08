class Ballot < ApplicationRecord
  include Encryptable

  MAX_QUESTION_LENGTH = 120

  enum category: [:yes_no]

  belongs_to :org

  validates :category,
    presence: true,
    inclusion: { in: categories }
  validates :org, presence: true
  validates :voting_ends_at, future: true

  has_encrypted :question, present: true, max_length: MAX_QUESTION_LENGTH
end
