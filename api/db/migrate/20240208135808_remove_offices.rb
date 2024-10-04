class RemoveOffices < ActiveRecord::Migration[7.0]
  def change
    remove_belongs_to :terms, :office,
      index: true,
      foreign_key: true,
      type: :uuid

    drop_table :offices, id: :uuid do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
