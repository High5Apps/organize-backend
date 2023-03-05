class Connection < ApplicationRecord
  belongs_to :sharer, class_name: 'User'
  belongs_to :scanner, class_name: 'User'

  validates :sharer, presence: true
  validates :scanner, presence: true
  validates_uniqueness_of :scanner,
    scope: :sharer,
    message: "is already connected to that user"
  validate :scanner_and_sharer_in_same_org?

  before_validation :set_scanner_org_from_sharer_org,
    if: -> { scanner.org.nil? },
    on: :create

  def self.directly_connected?(user_id, other_user_id)
    where(sharer_id: user_id, scanner_id: other_user_id).or(
      where(scanner_id: user_id, sharer_id: other_user_id)
    ).exists?
  end

  private

  def set_scanner_org_from_sharer_org
    scanner.update!(org: sharer.org);
  end

  def scanner_and_sharer_in_same_org?
    unless scanner&.org&.id == sharer&.org&.id
      errors.add(:base, 'You must be in the same org')
    end
  end
end
