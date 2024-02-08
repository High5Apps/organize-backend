class AddCategoryToTerms < ActiveRecord::Migration[7.0]
  def change
    add_column :terms, :category, :integer, null: false
  end
end
