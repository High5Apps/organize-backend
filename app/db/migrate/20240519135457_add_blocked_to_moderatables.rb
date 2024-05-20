class AddBlockedToModeratables < ActiveRecord::Migration[7.1]
  def change
    add_column :ballots, :blocked, :boolean, null: false, default: false
    add_column :comments, :blocked, :boolean, null: false, default: false
    add_column :posts, :blocked, :boolean, null: false, default: false
    add_column :users, :blocked, :boolean, null: false, default: false
  end
end
