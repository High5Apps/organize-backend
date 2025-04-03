class CreateWorkGroups < ActiveRecord::Migration[7.2]
  def change
    create_table :work_groups, id: :uuid do |t|
      t.jsonb :encrypted_department
      t.jsonb :encrypted_job_title, null: false
      t.jsonb :encrypted_shift, null: false
      t.belongs_to :user,
        index: true,
        foreign_key: true,
        type: :uuid,
        null: false

      t.timestamps
    end

    change_table :union_cards do |t|
      t.belongs_to :work_group, type: :uuid, foreign_key: true
      t.jsonb :encrypted_department
      t.jsonb :encrypted_job_title
      t.jsonb :encrypted_shift
    end
  end
end
