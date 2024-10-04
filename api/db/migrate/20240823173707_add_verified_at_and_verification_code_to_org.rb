class AddVerifiedAtAndVerificationCodeToOrg < ActiveRecord::Migration[7.1]
  def change
    add_column :orgs, :verified_at, :datetime
    add_column :orgs, :verification_code, :string, null: false
  end
end
