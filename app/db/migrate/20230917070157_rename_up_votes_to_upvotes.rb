class RenameUpVotesToUpvotes < ActiveRecord::Migration[7.0]
  def change
    rename_table :up_votes, :upvotes
  end
end
