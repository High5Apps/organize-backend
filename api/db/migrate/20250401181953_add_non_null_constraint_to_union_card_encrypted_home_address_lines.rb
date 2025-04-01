class AddNonNullConstraintToUnionCardEncryptedHomeAddressLines < ActiveRecord::Migration[7.2]
  def change
    change_column_null :union_cards, :encrypted_home_address_line1, false
    change_column_null :union_cards, :encrypted_home_address_line2, false
  end
end
