class RemoveUniqueIndiciesFromUpVotes < ActiveRecord::Migration[7.0]
  def change
    change_table :up_votes do |t|
      t.remove_index [:post_id, :user_id], unique: true
      t.remove_index [:comment_id, :user_id], unique: true
      t.index :post_id
      t.index :comment_id
    end
  end
end
