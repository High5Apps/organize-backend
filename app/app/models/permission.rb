class Permission < ApplicationRecord
  enum :scope, [
    :edit_permissions,
  ], validate: true

  belongs_to :org

  serialize :data, coder: PermissionData

  validates :org, presence: true
  validates_associated :data

  validate :president_can_edit_permissions
  validate :some_active_officer_has_permission, on: [:create, :update]

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
