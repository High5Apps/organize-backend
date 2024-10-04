class AddCandidateReferenceToPosts < ActiveRecord::Migration[7.0]
  def change
    add_reference :posts, :candidate, type: :uuid, foreign_key: true
  end
end
