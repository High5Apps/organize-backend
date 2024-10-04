class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts, id: :uuid do |t|
      t.integer :category, null: false
      t.string :title, null: false
      t.text :body
      t.belongs_to :user,
        index: true,
        foreign_key: true,
        type: :uuid
      t.timestamps
    end
  end
end
