class MakeOrgOptionalOnUsers < ActiveRecord::Migration[7.0]
  def change
    change_column_null :users, :org_id, true
  end
end
