class AddPolymorphicAssociationToFlaggedItems < ActiveRecord::Migration[7.1]
  def change
    change_table :flagged_items do |t|
      t.remove_index [:ballot_id, :user_id], unique: true
      t.remove_index [:comment_id, :user_id], unique: true
      t.remove_index [:post_id, :user_id], unique: true
      t.remove_belongs_to :ballot,
        foreign_key: true,
        index: false, # Handled by the multi-column index above
        null: true,
        type: :uuid
      t.remove_belongs_to :comment,
        foreign_key: true,
        index: false, # Handled by the multi-column index above
        null: true,
        type: :uuid
      t.remove_belongs_to :post,
        foreign_key: true,
        index: false, # Handled by the multi-column index above
        null: true,
        type: :uuid

      t.belongs_to :flaggable,
        index: false, # Handled by the multi-column index below
        null: false,
        polymorphic: true,
        type: :uuid
      t.index [:flaggable_type, :flaggable_id, :user_id], unique: true
    end
  end
end
