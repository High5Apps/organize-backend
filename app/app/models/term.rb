class Term < ApplicationRecord
  enum office: Office::TYPE_SYMBOLS

  belongs_to :user

  validates :ends_at,
    presence: true,
    after_created_at: true
  validates :office,
    presence: true,
    inclusion: { in: offices }
  validates :user, presence: true
end
