class RemovePotentialMemberDefinitionFromOrgs < ActiveRecord::Migration[7.0]
  def change
    remove_column :orgs, :potential_member_definition, :string
  end
end
