class AddOrgToPosts < ActiveRecord::Migration[7.0]
  def change
    add_reference :posts, :org, type: :uuid, null: false
  end
end
