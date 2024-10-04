class CreatePermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :permissions, id: :uuid do |t|
      t.jsonb :data, null: false
      t.belongs_to :org,
        index: false, # Handled by the multi-column index below
        foreign_key: true,
        type: :uuid,
        null: false
      t.integer :scope, null: false

      t.index [:org_id, :scope], unique: true

      t.timestamps
    end
  end
end
