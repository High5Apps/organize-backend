class Permission < ApplicationRecord
  enum :scope, [
    :edit_permissions,
  ], validate: true

  belongs_to :org

  validates :data, presence: true
  validates :org, presence: true
end
