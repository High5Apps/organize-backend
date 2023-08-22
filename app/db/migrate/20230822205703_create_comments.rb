class CreateComments < ActiveRecord::Migration[7.0]
  def change
    create_table :comments, id: :uuid do |t|
      t.text :body, null: false
      t.belongs_to :post,
        index: true,
        foreign_key: true,
        type: :uuid,
        null: false
      t.belongs_to :user,
        index: true,
        foreign_key: true,
        type: :uuid,
        null: false

      t.timestamps
    end
  end
end
