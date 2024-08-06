class ChangeBlockedToBlockedAt < ActiveRecord::Migration[7.1]
  def change
    remove_column :ballots, :blocked, :boolean, null: false, default: false
    remove_column :comments, :blocked, :boolean, null: false, default: false
    remove_column :posts, :blocked, :boolean, null: false, default: false
    remove_column :users, :blocked, :boolean, null: false, default: false

    add_column :ballots, :blocked_at, :datetime
    add_column :comments, :blocked_at, :datetime
    add_column :posts, :blocked_at, :datetime
    add_column :users, :blocked_at, :datetime
  end
end
