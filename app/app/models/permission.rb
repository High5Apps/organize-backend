class Permission < ApplicationRecord
  enum scope: [
    :edit_permissions,
  ]

  belongs_to :org

  validates :data, presence: true
  validates :org, presence: true
  validates :scope,
    presence: true,
    inclusion: { in: scopes }
end
