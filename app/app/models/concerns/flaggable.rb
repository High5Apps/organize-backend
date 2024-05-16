module Flaggable
  extend ActiveSupport::Concern

  included do
    belongs_to :user

    has_many :flags, as: :flaggable
    has_many :moderation_events, as: :moderatable

    has_one :last_moderation_event, -> { order(created_at: :desc) },
      as: :moderatable, class_name: 'ModerationEvent'

    validates :user, presence: true

    def encrypted_flaggable_title
      send(self.class.encrypted_flaggable_title)
    end
  end

  class_methods do
    attr_reader :encrypted_flaggable_title

    private

    def flaggable(title:)
      @encrypted_flaggable_title = title
    end
  end
end
