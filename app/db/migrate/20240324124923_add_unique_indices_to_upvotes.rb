class AddUniqueIndicesToUpvotes < ActiveRecord::Migration[7.0]
  def change
    change_table :upvotes do |t|
      t.remove_index :post_id
      t.remove_index :comment_id
      t.index [:post_id, :user_id], unique: true
      t.index [:comment_id, :user_id], unique: true
    end
  end
end
