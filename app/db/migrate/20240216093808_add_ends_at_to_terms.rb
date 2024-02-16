class AddEndsAtToTerms < ActiveRecord::Migration[7.0]
  def change
    add_column :terms, :ends_at, :datetime, null: false
  end
end
