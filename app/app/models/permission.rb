class Permission < ApplicationRecord
  enum :scope, [
    :edit_permissions,
  ], validate: true

  belongs_to :org

  serialize :data, coder: PermissionData

  validates :org, presence: true
  validates_associated :data

  validate :some_active_officer_has_permission, on: [:create, :update]

  private

  def some_active_officer_has_permission
    return unless data&.offices && org

    active_offices = org.terms.active_at(Time.now).pluck(:office).uniq
    if (active_offices & data.offices).blank?
      errors.add :base, 'At least one active officer must have permission'
    end
  end
end
