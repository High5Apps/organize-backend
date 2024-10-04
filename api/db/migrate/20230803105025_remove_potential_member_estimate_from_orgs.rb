class RemovePotentialMemberEstimateFromOrgs < ActiveRecord::Migration[7.0]
  def change
    remove_column :orgs, :potential_member_estimate, :integer, null: false
  end
end
