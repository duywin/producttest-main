class CartItemsController < ApplicationController
  before_action :set_cart, only: [:create, :apply_promotion]
  before_action :set_cart_item, only: [:update, :destroy]

  # Adds a product to the cart or updates the quantity if it already exists.
  def create
    product = Product.find_by(id: params[:product_id])
    unless product
      render json: { success: false, message: "Product not found" }, status: :not_found
      return
    end

    @cart_item = @cart.cart_items.find_or_initialize_by(
      product_id: product.id,
      is_anomaly: product.price_status == "anomaly"
    )

    @cart_item.quantity += params[:quantity].to_i
    @cart_item.price = product.current_price
    @cart_item.is_anomaly = product.price_status == "anomaly"

    if @cart_item.save
      render json: { success: true, message: "Item added to cart", cart_count: @cart.cart_items.sum(:quantity) }
    else
      render json: { success: false, message: "Failed to add item to cart" }, status: :unprocessable_entity
    end
  end

  # Updates the quantity of a cart item.
  def update
    if @cart_item.update(quantity: params[:quantity])
      render json: { success: true, message: "Quantity updated", new_quantity: @cart_item.quantity }
    else
      render json: { success: false, message: "Failed to update quantity" }, status: :unprocessable_entity
    end
  end

  # Removes a cart item.
  def destroy
    if @cart_item.destroy
      render json: { success: true, message: "Item removed from cart" }
    else
      render json: { success: false, message: "Failed to remove item" }, status: :unprocessable_entity
    end
  end

  # Applies a promotion to the cart.
  def apply_promotion
    promotion = Promotion.find_by(promote_code: params[:promote_code])
    unless promotion
      render json: { success: false, message: "Promotion not found" }, status: :not_found
      return
    end

    updated_prices = {}
    case promotion.promotion_type
    when "product"
      apply_product_discount(promotion, updated_prices)
    when "category"
      apply_category_discount(promotion, updated_prices)
    else
      render json: { success: false, message: "Invalid promotion type" }, status: :unprocessable_entity
      return
    end

    render json: { success: true, message: "Discount applied", updated_prices: updated_prices }
  end

  private

  # Applies a product-specific discount.
  def apply_product_discount(promotion, updated_prices)
    @cart.cart_items.each do |item|
      next unless item.product_id == promotion.apply_field.to_i

      calculate_discount(item, promotion.value, updated_prices)
    end
  end

  # Applies a category-specific discount.
  def apply_category_discount(promotion, updated_prices)
    @cart.cart_items.each do |item|
      next unless item.product.product_type == promotion.apply_field

      calculate_discount(item, promotion.value, updated_prices)
    end
  end

  # Calculates and applies the discount to a cart item.
  def calculate_discount(item, discount_rate, updated_prices)
    discount_value = item.price * (discount_rate / 100.0)
    new_price = [item.price - discount_value, 0].max

    updated_prices[item.id] = {
      old_price: item.price * item.quantity,
      new_price: new_price * item.quantity
    }
  end

  # Finds the cart based on the cart ID parameter.
  def set_cart
    @cart = Cart.find_by(id: params[:cart_id])
    unless @cart
      render json: { success: false, message: "Cart not found" }, status: :not_found
    end
  end

  # Finds the cart item based on the ID parameter.
  def set_cart_item
    @cart_item = CartItem.find_by(id: params[:id])
    unless @cart_item
      render json: { success: false, message: "Cart item not found" }, status: :not_found
    end
  end
end
