class AddLeftOrgAtToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :left_org_at, :datetime
  end
end
