class Comment < ApplicationRecord
  scope :created_before, ->(time) { where(created_at: ...time) }
  scope :includes_pseudonym, -> {
    select(:pseudonym).joins(:user).group(:id, :pseudonym)
  }
  scope :left_outer_joins_with_most_recent_upvotes_created_before, ->(time) {
    joins(%Q(
      LEFT OUTER JOIN (
        #{Upvote.most_recent_created_before(time).to_sql}
      ) AS upvotes
        ON upvotes.comment_id = comments.id
    ).gsub(/\s+/, ' '))
  }
  scope :order_by_hot_created_before, ->(time) {
    left_outer_joins_with_most_recent_upvotes_created_before(time)
      .order(Arel.sql(Comment.sanitize_sql_array([
        %(
          (1 + COALESCE(SUM(value), 0)) /
          (2 +
            (EXTRACT(EPOCH FROM (:cutoff_time - comments.created_at)) /
            :time_division)
          )^:gravity DESC, comments.id DESC
        ).gsub(/\s+/, ' '),
        cutoff_time: time,
        gravity: 0.975,
        time_division: 1.hour])))
      .group(:id)
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

  has_ancestry
end
