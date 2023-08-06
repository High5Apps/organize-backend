class Post < ApplicationRecord
  MAX_TITLE_LENGTH = 120
  MAX_BODY_LENGTH = 10000

  enum category: [:general, :grievances, :demands]

  belongs_to :org
  belongs_to :user

  validates :org, presence: true
  validates :category,
    presence: true,
    inclusion: { in: categories }
  validates :title,
    presence: true,
    length: { maximum: MAX_TITLE_LENGTH }
  validates :body,
    length: { maximum: MAX_BODY_LENGTH }
  validates :user, presence: true
end
