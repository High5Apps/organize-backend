class CreateVotes < ActiveRecord::Migration[7.0]
  def change
    create_table :votes, id: :uuid do |t|
      t.belongs_to :ballot,
        index: true,
        foreign_key: true,
        null: false,
        type: :uuid
      t.string :candidate_ids,
        array: true,
        null: false
      t.index :candidate_ids,
        using: :gin
      t.belongs_to :user,
        index: true,
        foreign_key: true,
        null: false,
        type: :uuid
      t.timestamps
    end
  end
end
