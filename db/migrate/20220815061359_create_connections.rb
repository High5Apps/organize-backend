class CreateConnections < ActiveRecord::Migration[7.0]
  def change
    create_table :connections, id: :uuid do |t|
      t.belongs_to :sharer,
        index: true,
        foreign_key: { to_table: :users },
        type: :uuid
      t.belongs_to :scanner,
        index: true,
        foreign_key: { to_table: :users },
        type: :uuid
      t.timestamps
    end
  end
end
