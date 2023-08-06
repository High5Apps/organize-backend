class UpdateReferencesToBeNonNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :connections, :sharer_id, false
    change_column_null :connections, :scanner_id, false

    change_column_null :posts, :user_id, false

    change_column_null :terms, :user_id, false
    change_column_null :terms, :office_id, false
  end
end
