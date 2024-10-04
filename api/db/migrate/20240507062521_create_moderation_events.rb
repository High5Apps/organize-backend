class CreateModerationEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :moderation_events, id: :uuid do |t|
      t.integer :action, null: false
      t.belongs_to :ballot,
        foreign_key: true,
        index: true,
        null: true,
        type: :uuid
      t.belongs_to :comment,
        foreign_key: true,
        index: true,
        null: true,
        type: :uuid
      t.belongs_to :moderator,
        foreign_key: { to_table: :users },
        index: true,
        null: false,
        type: :uuid
      t.belongs_to :post,
        foreign_key: true,
        index: true,
        null: true,
        type: :uuid
      t.belongs_to :user,
        foreign_key: true,
        index: true,
        null: true,
        type: :uuid

      t.timestamps
    end
  end
end
