class Connection < ApplicationRecord
  belongs_to :sharer, class_name: 'User'
  belongs_to :scanner, class_name: 'User'

  validates :sharer, presence: true
  validates :scanner, presence: true
  validates_uniqueness_of :scanner,
    scope: :sharer,
    message: "is already connected to that user"
end
