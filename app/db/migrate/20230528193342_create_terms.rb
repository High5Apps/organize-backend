class CreateTerms < ActiveRecord::Migration[7.0]
  def change
    create_table :terms, id: :uuid do |t|
      t.belongs_to :user,
        index: true,
        foreign_key: true,
        type: :uuid
      t.belongs_to :office,
        index: true,
        foreign_key: true,
        type: :uuid
      t.timestamps
    end
  end
end
