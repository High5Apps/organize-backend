class AddTermStartsAtToBallots < ActiveRecord::Migration[7.0]
  def change
    add_column :ballots, :term_starts_at, :datetime
  end
end
