class AddEncryptedNameToOrgs < ActiveRecord::Migration[7.0]
  def change
    add_column :orgs, :encrypted_name, :jsonb
  end
end
