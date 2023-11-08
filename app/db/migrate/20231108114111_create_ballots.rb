class CreateBallots < ActiveRecord::Migration[7.0]
  def change
    create_table :ballots, id: :uuid do |t|
      t.belongs_to :org,
        index: true,
        foreign_key: true,
        type: :uuid,
        null: false
      t.jsonb :encrypted_question, null: false
      t.datetime :voting_ends_at, null: false
      t.integer :category, null: false

      t.timestamps
    end
  end
end
