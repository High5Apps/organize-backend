class Upvote < ApplicationRecord
  scope :created_at_or_before, ->(time) {
    where(created_at: ..time)
  }

  belongs_to :comment, optional: true
  belongs_to :post, optional: true
  belongs_to :user

  has_one :org, through: :user

  validates :comment, same_org: :user, if: :comment
  validates :post, same_org: :user, if: :post
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
      errors.add :base, :on_comment_and_post
    end
  end
end
