class Connection < ApplicationRecord
  belongs_to :sharer, class_name: 'User'
  belongs_to :scanner, class_name: 'User'

  validates :sharer, presence: true
  validates :scanner, presence: true
  validates_uniqueness_of :scanner,
    scope: :sharer,
    message: "is already connected to that user"

  def self.directly_connected?(user_id, other_user_id)
    where(sharer_id: user_id, scanner_id: other_user_id).or(
      where(scanner_id: user_id, sharer_id: other_user_id)
    ).exists?
  end
end
