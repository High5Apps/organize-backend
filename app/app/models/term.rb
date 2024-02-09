class Term < ApplicationRecord
  enum office: Office::TYPE_SYMBOLS

  belongs_to :user

  validates :office,
    presence: true,
    inclusion: { in: offices }
  validates :user, presence: true
end
