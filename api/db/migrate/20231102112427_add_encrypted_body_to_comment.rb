class AddEncryptedBodyToComment < ActiveRecord::Migration[7.0]
  def change
    add_column :comments, :encrypted_body, :jsonb
  end
end
