class CreateOrgs < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
    create_table :orgs, id: :uuid do |t|
      t.string :name, null: false
      t.string :potential_member_definition, null: false
      t.integer :potential_member_estimate, null: false

      t.timestamps
    end
  end
end
