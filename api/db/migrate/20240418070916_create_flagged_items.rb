class CreateFlaggedItems < ActiveRecord::Migration[7.1]
  def change
    create_table :flagged_items, id: :uuid do |t|
      t.belongs_to :ballot,
        foreign_key: true,
        index: false, # Handled by the multi-column index below
        null: true,
        type: :uuid
      t.belongs_to :comment,
        foreign_key: true,
        index: false, # Handled by the multi-column index below
        null: true,
        type: :uuid
      t.belongs_to :post,
        foreign_key: true,
        index: false, # Handled by the multi-column index below
        null: true,
        type: :uuid
      t.belongs_to :user,
        foreign_key: true,
        index: true,
        null: false,
        type: :uuid

      t.index [:ballot_id, :user_id], unique: true
      t.index [:comment_id, :user_id], unique: true
      t.index [:post_id, :user_id], unique: true

      t.timestamps
    end
  end
end
