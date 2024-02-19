class CreateNominations < ActiveRecord::Migration[7.0]
  def change
    create_table :nominations, id: :uuid do |t|
      t.belongs_to :ballot,
        index: true,
        foreign_key: true,
        null: false,
        type: :uuid
      t.belongs_to :nominator,
        index: true,
        foreign_key: { to_table: :users },
        null: false,
        type: :uuid
      t.belongs_to :nominee,
        index: false, # Handled by the 2-column index below
        foreign_key: { to_table: :users },
        null: false,
        type: :uuid
      t.index [:nominee_id, :ballot_id], unique: true
      t.boolean :accepted
      t.timestamps
    end
  end
end
