class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, presence: true, numericality: {only_integer: true, greater_than: 0}
  def calculate_price
    product.current_price * quantity
  end
  def self.current_month_category_sales
    current_month = Date.current.strftime("%Y-%m")
    joins(:product)
      .where("DATE_FORMAT(cart_items.created_at, '%Y-%m') = ?", current_month)
      .group("products.product_type")
      .sum(:quantity)
      .map { |category, quantity| { name: category, y: quantity } }
  end
end
