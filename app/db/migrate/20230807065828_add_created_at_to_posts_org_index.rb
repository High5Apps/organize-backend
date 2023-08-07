class AddCreatedAtToPostsOrgIndex < ActiveRecord::Migration[7.0]
  def change
    remove_index :posts, :org_id
    add_index :posts, [:org_id, :created_at]
  end
end
