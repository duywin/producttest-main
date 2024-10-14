class CreateMerchandises < ActiveRecord::Migration[7.1]
  def change
    create_table :merchandises do |t|
      t.references :product, null: false, foreign_key: true
      t.decimal :cut_off_value, precision: 10, scale: 2
      t.date :promotion_end
      t.timestamps
    end
  end
end
