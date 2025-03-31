class AddEncryptedHomeAddressLine2ToUnionCards < ActiveRecord::Migration[7.2]
  def change
    rename_column :union_cards, :encrypted_home_address,
      :encrypted_home_address_line1
    add_column :union_cards, :encrypted_home_address_line2, :jsonb
  end
end
