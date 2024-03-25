class AddUniqueIndexToVotes < ActiveRecord::Migration[7.0]
  def change
    change_table :votes do |t|
      t.remove_index :ballot_id
      t.remove_index :user_id
      t.index [:ballot_id, :user_id], unique: true
    end
  end
end
