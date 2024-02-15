class AddUserReferenceToCandidates < ActiveRecord::Migration[7.0]
  def change
    add_reference :candidates, :user, type: :uuid, foreign_key: true
    change_column_null :candidates, :encrypted_title, true
  end
end
