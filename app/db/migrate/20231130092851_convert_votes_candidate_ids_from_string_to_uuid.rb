class ConvertVotesCandidateIdsFromStringToUuid < ActiveRecord::Migration[7.0]
  def change
    remove_column :votes, :candidate_ids, :string, array: true, null: false
    remove_index :votes, :candidate_ids, using: :gin, if_exists: true

    add_column :votes, :candidate_ids, :uuid, array: true, null: false
    add_index :votes, :candidate_ids, using: :gin
  end
end
