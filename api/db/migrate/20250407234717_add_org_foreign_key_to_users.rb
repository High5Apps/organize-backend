class AddOrgForeignKeyToUsers < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :users, :orgs
  end
end
