class AddRecruitedByToUsers < ActiveRecord::Migration[7.0]
  def change
    add_reference :users, :recruiter,
      foreign_key: { to_table: :users }, index: true, type: :uuid
  end
end
