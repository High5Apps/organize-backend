class AddEncryptedTitleToPost < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :encrypted_title, :jsonb
  end
end
