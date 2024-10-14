class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.text :name
      t.text :product_type
      t.text :prices
      t.text :desc
      t.integer :stock
      t.text :picture

      t.timestamps
    end
  end
end
