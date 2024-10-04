class RemoveNameFromOrgs < ActiveRecord::Migration[7.0]
  def change
    remove_column :orgs, :name, :string
  end
end
