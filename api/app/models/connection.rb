class Connection < ApplicationRecord
  scope :created_at_or_before, ->(time) { where(created_at: ..time) }

  belongs_to :scanner, class_name: 'User', inverse_of: :scanned_connections
  belongs_to :sharer, class_name: 'User', inverse_of: :shared_connections

  validates :scanner,
    presence: true,
    same_org: { as: :sharer, message: :different_orgs }
  validates :sharer, presence: true

  validate :not_already_connected, on: :create
  validate :sharer_and_scanner_not_equal

  before_validation :set_scanner_info_from_sharer_info,
    if: -> { scanner.org.nil? },
    on: :create

  after_create -> { scanner.save! },
    if: -> { @did_set_scanner_info_from_sharer_info }

  def self.directly_connected?(user_id, other_user_id)
    between(user_id, other_user_id).present?
  end

  def self.between(user_id, other_user_id)
    where(sharer_id: user_id, scanner_id: other_user_id).or(
      where(scanner_id: user_id, sharer_id: other_user_id)
    ).first
  end

  private

  def set_scanner_info_from_sharer_info
    scanner.org = sharer.org
    scanner.recruiter = sharer
    @did_set_scanner_info_from_sharer_info = true
  end

  def not_already_connected
    if scanner&.directly_connected_to? sharer
      errors.add :base, :already_connected
    end
  end

  def sharer_and_scanner_not_equal
    unless scanner&.id != sharer&.id
      errors.add :base, :self_connection
    end
  end
end
