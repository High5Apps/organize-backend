class Permission < ApplicationRecord
  enum :scope, [
    :edit_permissions,
  ], validate: true

  belongs_to :org

  serialize :data, coder: PermissionData

  validates :org, presence: true
  validates_associated :data
end
