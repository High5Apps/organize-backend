class UpVote < ApplicationRecord
  ERROR_EXACTLY_ONE_COMMENT_OR_POST = \
    'Up votes must be associated with exactly one comment or post'

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
