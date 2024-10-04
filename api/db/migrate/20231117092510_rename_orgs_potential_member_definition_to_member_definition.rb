class RenameOrgsPotentialMemberDefinitionToMemberDefinition < ActiveRecord::Migration[7.0]
  def change
    rename_column :orgs,
      :encrypted_potential_member_definition,
      :encrypted_member_definition
  end
end
