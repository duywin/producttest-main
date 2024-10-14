class CreateCarts < ActiveRecord::Migration[7.1]
  def change
    create_table :carts do |t|
      t.integer :account_id, null: true
      t.boolean :check_out
      t.integer :total_price
      t.integer :quantity
      t.text :address
      t.text :status
      t.date :deliver_day
      t.timestamps
    end
  end
end
