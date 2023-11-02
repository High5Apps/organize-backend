class RemoveBodyFromPosts < ActiveRecord::Migration[7.0]
  def change
    remove_column :posts, :body, :string
  end
end
