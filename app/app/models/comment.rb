class Comment < ApplicationRecord
  scope :created_before, ->(time) { where(created_at: ...time) }
  scope :left_outer_joins_with_most_recent_upvotes_created_before, ->(time) {
    joins(%Q(
      LEFT OUTER JOIN (
        #{Upvote.most_recent_created_before(time).to_sql}
      ) AS upvotes
        ON upvotes.comment_id = comments.id
    ).gsub(/\s+/, ' '))
  }

  MAX_BODY_LENGTH = 10000

  belongs_to :post
  belongs_to :user

  has_many :upvotes

  validates :post, presence: true
  validates :user, presence: true
  validates :body,
    presence: true,
    length: { maximum: MAX_BODY_LENGTH }
end
