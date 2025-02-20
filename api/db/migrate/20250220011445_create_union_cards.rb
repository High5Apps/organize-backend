class CreateUnionCards < ActiveRecord::Migration[7.2]
  def change
    create_table :union_cards, id: :uuid do |t|
      t.jsonb :encrypted_agreement, null: false
      t.jsonb :encrypted_email, null: false
      t.jsonb :encrypted_employer_name, null: false
      t.jsonb :encrypted_name, null: false
      t.jsonb :encrypted_phone, null: false
      t.binary :signature_bytes, null: false
      t.belongs_to :user,
        index: true,
        foreign_key: true,
        type: :uuid,
        null: false
      t.datetime :signed_at, null: false

      t.timestamps
    end
  end
end
