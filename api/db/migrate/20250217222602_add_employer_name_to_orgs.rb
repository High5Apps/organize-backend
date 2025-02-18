class AddEmployerNameToOrgs < ActiveRecord::Migration[7.2]
  def change
    add_column :orgs, :encrypted_employer_name, :jsonb
  end
end
