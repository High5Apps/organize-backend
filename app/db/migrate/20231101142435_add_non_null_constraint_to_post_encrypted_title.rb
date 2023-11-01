class AddNonNullConstraintToPostEncryptedTitle < ActiveRecord::Migration[7.0]
  def change
    change_column_null :posts, :encrypted_title, false
  end
end
