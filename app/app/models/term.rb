class Term < ApplicationRecord
  belongs_to :user
  belongs_to :office

  validates :user, presence: true
  validates :office, presence: true
end
