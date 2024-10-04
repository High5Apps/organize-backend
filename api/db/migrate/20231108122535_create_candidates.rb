class CreateCandidates < ActiveRecord::Migration[7.0]
  def change
    create_table :candidates, id: :uuid do |t|
      t.belongs_to :ballot,
        index: true,
        foreign_key: true,
        type: :uuid,
        null: false
      t.jsonb :encrypted_title, null: false

      t.timestamps
    end
  end
end
