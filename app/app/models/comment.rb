class Comment < ApplicationRecord
  MAX_BODY_LENGTH = 10000

  belongs_to :post
  belongs_to :user

  has_many :up_votes

  validates :post, presence: true
  validates :user, presence: true
  validates :body,
    presence: true,
    length: { maximum: MAX_BODY_LENGTH }
end
