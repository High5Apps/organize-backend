class Term < ApplicationRecord
  enum office: [
    :founder,
    :president,
    :vice_president,
    :secretary,
    :treasurer,
    :steward,
    :trustee,
  ]

  belongs_to :user

  validates :office,
    presence: true,
    inclusion: { in: offices }
  validates :user, presence: true
end
