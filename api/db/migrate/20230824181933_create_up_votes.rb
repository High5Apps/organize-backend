class CreateUpVotes < ActiveRecord::Migration[7.0]
  def change
    create_table :up_votes, id: :uuid do |t|
      t.integer :value, null: false
      t.belongs_to :user,
        index: true,
        foreign_key: true,
        type: :uuid,
        null: false
      t.belongs_to :post,
        index: false, # Covered by the multicolumn index in line 18 below
        foreign_key: true,
        type: :uuid
      t.belongs_to :comment,
        index: false, # Covered by the multicolumn index in line 19 below
        foreign_key: true,
        type: :uuid
      t.index [:post_id, :user_id], unique: true
      t.index [:comment_id, :user_id], unique: true

      t.timestamps
    end
  end
end
