class RenameFlaggedItemsToFlags < ActiveRecord::Migration[7.1]
  def change
    rename_table :flagged_items, :flags
  end
end
