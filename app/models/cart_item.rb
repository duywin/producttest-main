class CartItem < ApplicationRecord
  # Associations
  belongs_to :cart
  belongs_to :product

  # Validations
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # Instance Methods

  # Calculate the total price for the cart item based on the current product price
  def calculate_price
    product.current_price * quantity
  end

  # Class Methods

  # Fetch current month's sales data grouped by product categories
  def self.current_month_category_sales
    current_month = Date.current.strftime("%Y-%m")
    joins(:product)
      .where("DATE_FORMAT(cart_items.created_at, '%Y-%m') = ?", current_month)
      .group("products.product_type")
      .sum(:quantity)
      .map { |category, quantity| { name: category, y: quantity } }
  end
end
