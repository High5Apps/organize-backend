class Post < ApplicationRecord
  scope :created_before, ->(time) { where(created_at: ...time) }
  scope :left_outer_joins_with_most_recent_upvotes_created_before, ->(time) {
    joins(%Q(
      LEFT OUTER JOIN (
        #{Upvote.most_recent_created_before(time).to_sql}
      ) AS upvotes
        ON upvotes.post_id = posts.id
    ).gsub(/\s+/, ' '))
  }

  MAX_TITLE_LENGTH = 120
  MAX_BODY_LENGTH = 10000

  enum category: [:general, :grievances, :demands]

  belongs_to :org
  belongs_to :user

  has_many :comments
  has_many :upvotes

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
