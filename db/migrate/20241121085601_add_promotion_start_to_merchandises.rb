class AddPromotionStartToMerchandises < ActiveRecord::Migration[7.1]
  def change
    add_column :merchandises, :promotion_start, :date
  end
end
