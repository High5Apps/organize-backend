class AddPolymorphicAssociationToModerationEvents < ActiveRecord::Migration[7.1]
  def change
    change_table :moderation_events do |t|
      t.remove_belongs_to :ballot,
        foreign_key: true,
        index: true,
        null: true,
        type: :uuid
      t.remove_belongs_to :comment,
        foreign_key: true,
        index: true,
        null: true,
        type: :uuid
      t.remove_belongs_to :post,
        foreign_key: true,
        index: true,
        null: true,
        type: :uuid
      t.remove_belongs_to :user,
        foreign_key: true,
        index: true,
        null: true,
        type: :uuid

      t.belongs_to :moderatable,
        index: true,
        null: false,
        polymorphic: true,
        type: :uuid
      t.rename :moderator_id, :user_id
    end
  end
end
