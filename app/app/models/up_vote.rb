class UpVote < ApplicationRecord
  scope :most_recent_created_before, ->(time) {
    most_recent_up_vote_for_each_user_on_each_up_votable_before_time = select(
      '*',
      %(
        FIRST_VALUE(up_votes.id) OVER (
          PARTITION BY up_votes.user_id, up_votes.post_id, up_votes.comment_id
          ORDER BY up_votes.created_at DESC, up_votes.id DESC
        ) AS first_id
      ).gsub(/\s+/, ' ')
    ).where('up_votes.created_at < ?', time)

    from(
      most_recent_up_vote_for_each_user_on_each_up_votable_before_time,
      :up_votes
    ).where('up_votes.id = first_id')
  }

  ERROR_EXACTLY_ONE_COMMENT_OR_POST = \
    'Up votes must be associated with exactly one comment or post'

  FAR_FUTURE_TIME = 1.year.from_now.freeze

  belongs_to :comment, optional: true
  belongs_to :post, optional: true
  belongs_to :user

  validates :user, presence: true
  validates :value,
    numericality: {
      greater_than_or_equal_to: -1,
      less_than_or_equal_to: 1,
      only_integer: true,
    }

  validate :exactly_one_of_comment_or_post_present

  private

  def exactly_one_of_comment_or_post_present
    unless [comment, post].compact.length == 1
      errors.add(:base, ERROR_EXACTLY_ONE_COMMENT_OR_POST)
    end
  end
end
