class AddJoinedAtToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :joined_at, :datetime
  end
end
