class AddAncestryToComments < ActiveRecord::Migration[7.0]
  def change
    change_table :comments do |t|
      t.string :ancestry, collation: 'C', null: false
      t.index :ancestry
    end
  end
end
