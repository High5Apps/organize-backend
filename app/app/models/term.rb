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
  belongs_to :office

  validates :category,
    presence: true,
    inclusion: { in: categories }
  validates :user, presence: true
  validates :office, presence: true
end
