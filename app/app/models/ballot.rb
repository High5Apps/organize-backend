class Ballot < ApplicationRecord
  include Encryptable

  scope :active_at, ->(time) { where.not(voting_ends_at: ..time) }
  scope :created_before, ->(time) { where(created_at: ...time) }
  scope :inactive_at, ->(time) { where(voting_ends_at: ..time) }

  MAX_QUESTION_LENGTH = 140

  enum category: [:yes_no]

  belongs_to :org

  has_many :candidates

  validates :category,
    presence: true,
    inclusion: { in: categories }
  validates :org, presence: true
  validates :voting_ends_at, future: true

  has_encrypted :question, present: true, max_length: MAX_QUESTION_LENGTH
end
