class AddEncryptedHomeAddressToUnionCards < ActiveRecord::Migration[7.2]
  def change
    add_column :union_cards, :encrypted_home_address, :jsonb
  end
end
