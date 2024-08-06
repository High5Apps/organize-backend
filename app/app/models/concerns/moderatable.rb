module Moderatable
  extend ActiveSupport::Concern

  included do
    scope :blocked, -> { where.not(blocked_at: nil) }
    scope :omit_blocked, -> { where(blocked_at: nil) }

    has_many :moderation_events, as: :moderatable

    has_one :last_moderation_event, -> { order(created_at: :desc) },
      as: :moderatable, class_name: 'ModerationEvent'
  end

  def block
    update! blocked_at: Time.now.utc
  end

  def unblock
    update! blocked_at: nil
  end
end
