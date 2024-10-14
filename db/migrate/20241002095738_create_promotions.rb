class CreatePromotions < ActiveRecord::Migration[6.1]
  def change
    create_table :promotions do |t|
      t.string :promote_code, null: false
      t.string :promotion_type, null: false
      t.string :apply_field
      t.decimal :value, precision: 10, scale: 2
      t.date :end_date
      t.integer :min_quantity, default: 0
      t.timestamps
    end
  end
end
