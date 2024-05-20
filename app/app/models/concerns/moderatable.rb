module Moderatable
  extend ActiveSupport::Concern

  included do
    has_many :moderation_events, as: :moderatable

    has_one :last_moderation_event, -> { order(created_at: :desc) },
      as: :moderatable, class_name: 'ModerationEvent'
  end
end
