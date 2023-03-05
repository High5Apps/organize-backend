class AddPseudonymToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :pseudonym, :string
  end
end
