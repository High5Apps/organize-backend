class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users, id: :uuid do |t|
      t.references :org, type: :uuid, null: false
      t.binary :public_key, null: false
      t.timestamps
    end
  end
end
