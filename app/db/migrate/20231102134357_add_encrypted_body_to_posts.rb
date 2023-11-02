class AddEncryptedBodyToPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :encrypted_body, :jsonb
  end
end
