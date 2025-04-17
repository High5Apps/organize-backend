class AddUniqueIndexToPostsOnCandidate < ActiveRecord::Migration[7.2]
  def change
    change_table :posts do |t|
      t.remove_index :candidate_id
      t.index :candidate_id, unique: true
    end
  end
end
