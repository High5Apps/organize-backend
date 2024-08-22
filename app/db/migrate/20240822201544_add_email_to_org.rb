class AddEmailToOrg < ActiveRecord::Migration[7.1]
  def change
    add_column :orgs, :email, :string, null: false
    add_index :orgs, :email, unique: true
  end
end
