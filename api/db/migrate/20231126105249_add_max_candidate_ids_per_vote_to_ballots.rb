class AddMaxCandidateIdsPerVoteToBallots < ActiveRecord::Migration[7.0]
  def change
    add_column :ballots, :max_candidate_ids_per_vote, :integer, null: false, default: 1
  end
end
