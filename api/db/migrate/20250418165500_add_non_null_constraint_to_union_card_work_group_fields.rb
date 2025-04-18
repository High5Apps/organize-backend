class AddNonNullConstraintToUnionCardWorkGroupFields < ActiveRecord::Migration[7.2]
  def change
    change_column_null :union_cards, :work_group_id, false
    change_column_null :union_cards, :encrypted_job_title, false
    change_column_null :union_cards, :encrypted_shift, false
  end
end
