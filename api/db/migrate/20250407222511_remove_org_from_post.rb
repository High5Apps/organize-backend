class RemoveOrgFromPost < ActiveRecord::Migration[7.2]
  def change
    remove_index :posts, [:org_id, :created_at]
    add_index :posts, :created_at
    remove_reference :posts, :org, type: :uuid, null: false
  end
end
