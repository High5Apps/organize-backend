module Flaggable
  extend ActiveSupport::Concern
  include Moderatable

  included do
    belongs_to :user

    has_many :flags, as: :flaggable

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
