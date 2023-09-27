class AddDepthCacheToComments < ActiveRecord::Migration[7.0]
  def change
    change_table(:comments) do |t|
      t.integer 'depth', default: 0, null: false
    end
  end
end
