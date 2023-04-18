class Connection < ApplicationRecord
  ERROR_MESSAGE_ALREADY_CONNECTED = "You're already connected to that user";

  belongs_to :sharer, class_name: 'User'
  belongs_to :scanner, class_name: 'User'

  validates :sharer, presence: true
  validates :scanner, presence: true
  validate :not_already_connected, on: :create
  validate :scanner_and_sharer_in_same_org?

  before_validation :set_scanner_org_from_sharer_org,
    if: -> { scanner.org.nil? },
    on: :create

  def self.directly_connected?(user_id, other_user_id)
    between(user_id, other_user_id).present?
  end

  def self.between(user_id, other_user_id)
    where(sharer_id: user_id, scanner_id: other_user_id).or(
      where(scanner_id: user_id, sharer_id: other_user_id)
    ).first
  end

  private

  def set_scanner_org_from_sharer_org
    scanner.update!(org: sharer.org);
  end

  def not_already_connected
    if scanner&.directly_connected_to? sharer
      errors.add(:base, ERROR_MESSAGE_ALREADY_CONNECTED)
    end
  end

  def scanner_and_sharer_in_same_org?
    unless scanner&.org&.id == sharer&.org&.id
      errors.add(:base, 'You must be in the same org')
    end
  end
end
