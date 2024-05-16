class Comment < ApplicationRecord
  include Encryptable
  include Flaggable

  scope :created_at_or_before, ->(time) { where(created_at: ..time) }
  scope :with_upvotes_created_at_or_before, ->(time) {
    with(upvotes: Upvote.created_at_or_before(time))
      .left_outer_joins(:upvotes)
  }
  scope :select_my_upvote, ->(my_id) {
    # Must be used with_upvotes_created_at_or_before.

    # Even though there is at most one upvote per requester per comment, SUM is
    # needed because an aggregate function is required
    select(Comment.sanitize_sql_array([
      "SUM(CASE WHEN upvotes.user_id = :my_id THEN value ELSE 0 END) AS my_vote",
      my_id:]))
  }
  scope :includes_pseudonym, -> {
    select(:pseudonym).joins(:user).group(:id, :pseudonym)
  }
  scope :select_upvote_score, -> {
    # Must be used with_upvotes_created_at_or_before
    select('COALESCE(SUM(value), 0) AS score')
  }
  scope :order_by_hot_created_at_or_before, ->(time) {
    # Must be used with_upvotes_created_at_or_before
    order(Arel.sql(Comment.sanitize_sql_array([
        %(
          (1 + COALESCE(SUM(value), 0)) /
          (2 +
            (EXTRACT(EPOCH FROM (:cutoff_time - comments.created_at)) /
            :time_division)
          )^:gravity DESC, comments.id DESC
        ).gsub(/\s+/, ' '),
        cutoff_time: time,
        gravity: 0.975,
        time_division: 1.hour.to_i])))
      .group(:id)
  }

  MAX_BODY_LENGTH = 10000
  MAX_COMMENT_DEPTH = 8

  attr_accessor :comment_id

  belongs_to :post

  has_many :upvotes

  validates :post, presence: true, same_org: :user
  validates :depth,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than: MAX_COMMENT_DEPTH,
      only_integer: true,
    }

  before_validation :set_post_from_comment_id, on: :create, if: :comment_id
  after_create :create_upvote_for_user

  has_encrypted :body, present: true, max_length: MAX_BODY_LENGTH
  has_ancestry cache_depth: true, depth_cache_column: :depth
  flaggable title: :encrypted_body

  private

  def create_upvote_for_user
    upvotes.create! user:, value: 1
  end

  def set_post_from_comment_id
    comment = Comment.includes(:post).find_by id: comment_id
    self.post = comment&.post
    self.comment_id = nil
  end
end
