class AddBallotReferenceToTerms < ActiveRecord::Migration[7.0]
  def change
    add_reference :terms, :ballot, foreign_key: true, type: :uuid
  end
end
