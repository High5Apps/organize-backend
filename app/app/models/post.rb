class Post < ApplicationRecord
  include Encryptable

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
  validates :user, presence: true

  after_create :create_upvote_for_user

  has_encrypted :title, present: true, max_length: MAX_TITLE_LENGTH
  has_encrypted :body, max_length: MAX_BODY_LENGTH

  private

  def create_upvote_for_user
    upvotes.create! user: user, value: 1
  end
end
