class RemoveOrgFromBallots < ActiveRecord::Migration[7.0]
  def change
    remove_reference :ballots, :org, type: :uuid, null: false, foreign_key: true
  end
end
