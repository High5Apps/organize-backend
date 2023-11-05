class AddNonNullConstraintToOrgEncryptedName < ActiveRecord::Migration[7.0]
  def change
    change_column_null :orgs, :encrypted_name, false
  end
end
