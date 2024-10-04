class AddEncryptedPotentialMemberDefinitionToOrgs < ActiveRecord::Migration[7.0]
  def change
    add_column :orgs, :encrypted_potential_member_definition, :jsonb,
      null: false
  end
end
