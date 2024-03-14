class AddAcceptedToTerms < ActiveRecord::Migration[7.0]
  def change
    add_column :terms, :accepted, :boolean, null: false
  end
end
