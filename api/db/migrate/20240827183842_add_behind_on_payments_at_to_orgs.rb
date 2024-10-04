class AddBehindOnPaymentsAtToOrgs < ActiveRecord::Migration[7.1]
  def change
    add_column :orgs, :behind_on_payments_at, :datetime
  end
end
