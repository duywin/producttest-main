class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items
  belongs_to :account
  paginates_per 10
  def total_price
    cart_items.includes(:product).sum("cart_items.quantity * products.prices")
  end
end
