class Term < ApplicationRecord
  enum category: [
    :founder,
    :president,
    :vice_president,
    :secretary,
    :treasurer,
    :steward,
    :trustee,
  ]

  belongs_to :user

  validates :category,
    presence: true,
    inclusion: { in: categories }
  validates :user, presence: true
end
