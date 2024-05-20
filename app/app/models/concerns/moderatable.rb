module Moderatable
  extend ActiveSupport::Concern

  included do
    has_many :moderation_events, as: :moderatable

    has_one :last_moderation_event, -> { order(created_at: :desc) },
      as: :moderatable, class_name: 'ModerationEvent'
  end

  def block
    update! blocked: true
  end

  def unblock
    update! blocked: false
  end
end
