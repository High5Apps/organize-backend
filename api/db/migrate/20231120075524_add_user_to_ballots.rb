class AddUserToBallots < ActiveRecord::Migration[7.0]
  def change
    add_reference :ballots, :user, type: :uuid, null: false, foreign_key: true
  end
end
