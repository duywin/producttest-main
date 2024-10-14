class CreatePromoteProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :promote_products do |t|
      t.references :promotion, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :amount

      t.timestamps
    end
  end
end
