class AddStartsAtToTerms < ActiveRecord::Migration[7.0]
  def change
    add_column :terms, :starts_at, :datetime, null: false
  end
end
