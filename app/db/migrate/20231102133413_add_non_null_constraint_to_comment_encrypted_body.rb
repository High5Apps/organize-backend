class AddNonNullConstraintToCommentEncryptedBody < ActiveRecord::Migration[7.0]
  def change
    change_column_null :comments, :encrypted_body, false
  end
end
