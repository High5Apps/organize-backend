class Permission < ApplicationRecord
  SCOPE_SYMBOLS = [
    :edit_permissions,
    :create_elections,
  ].freeze

  enum :scope, SCOPE_SYMBOLS, validate: true

  belongs_to :org

  serialize :data, coder: Data

  validates :org, presence: true
  validates_associated :data

  validate :president_can_edit_permissions
  validate :some_active_officer_has_permission, on: [:create, :update]

  def self.can?(user, scope)
    permission_data = who_can(scope, user.org)
    return false unless permission_data

    active_offices = user.terms.active_at(Time.now).pluck :office
    return (active_offices & permission_data.offices).present?
  end

  def self.who_can(scope, org)
    return nil unless org && SCOPE_SYMBOLS.include?(scope.to_sym)

    permission = org.permissions.find_by(scope:)
    permission&.data || Data.new(Defaults[scope])
  end

  private

  def president_can_edit_permissions
    return unless edit_permissions? && data&.offices

    unless data.offices.include? 'president'
      errors.add :base, 'President must be allowed to edit permissions'
    end
  end

  def some_active_officer_has_permission
    return unless data&.offices && org

    active_offices = org.terms.active_at(Time.now).pluck(:office).uniq
    if (active_offices & data.offices).blank?
      errors.add :base, 'At least one active officer must have permission'
    end
  end
end
