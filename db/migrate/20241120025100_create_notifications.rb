class CreateNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :notifications do |t|
      t.integer :admin_id
      t.string :message
      t.string :link
      t.boolean :read, default: false

      t.timestamps
    end
  end
end
