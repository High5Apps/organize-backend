class RenameUserPublicKeyToPublicKeyBytes < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.rename :public_key, :public_key_bytes
    end
  end
end
