class AddUniqueIndexToUnionCards < ActiveRecord::Migration[7.2]
  def change
    change_table :union_cards do |t|
      t.remove_index :user_id
      t.index :user_id, unique: true
    end
  end
end
