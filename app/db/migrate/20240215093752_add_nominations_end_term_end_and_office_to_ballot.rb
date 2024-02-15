class AddNominationsEndTermEndAndOfficeToBallot < ActiveRecord::Migration[7.0]
  def change
    add_column :ballots, :office, :integer
    add_column :ballots, :nominations_end_at, :datetime
    add_column :ballots, :term_ends_at, :datetime
  end
end
