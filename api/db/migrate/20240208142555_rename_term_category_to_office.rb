class RenameTermCategoryToOffice < ActiveRecord::Migration[7.0]
  def change
    rename_column :terms, :category, :office
  end
end
