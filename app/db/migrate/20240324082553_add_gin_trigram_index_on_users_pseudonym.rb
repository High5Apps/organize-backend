class AddGinTrigramIndexOnUsersPseudonym < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :pseudonym, using: :gin, opclass: :gin_trgm_ops
  end
end
