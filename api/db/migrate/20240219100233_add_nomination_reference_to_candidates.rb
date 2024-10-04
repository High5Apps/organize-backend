class AddNominationReferenceToCandidates < ActiveRecord::Migration[7.0]
  def change
    add_reference :candidates, :nomination, type: :uuid, foreign_key: true
  end
end
