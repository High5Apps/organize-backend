class AddDeletedAtToCommentsAndPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :comments, :deleted_at, :datetime
    add_column :posts, :deleted_at, :datetime
  end
end
