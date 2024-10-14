class CartItemsController < ApplicationController
  before_action :set_cart, only: [:create, :apply_promotion]

  def create
    product = Product.find(params[:product_id])
    @cart_item = @cart.cart_items.find_or_initialize_by(product_id: product.id, is_anomaly: product.price_status == 'anomaly')
    if @cart_item.persisted?
      @cart_item.quantity += params[:quantity].to_i
    else
      @cart_item.quantity = params[:quantity].to_i
    end

    @cart_item.price = product.current_price
    @cart_item.is_anomaly = product.price_status == 'anomaly'

    if @cart_item.save
      render json: { success: true, message: "Item added to cart", cart_count: @cart.cart_items.sum(:quantity) }
    else
      render json: { success: false, message: "Failed to add item to cart" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: "Product not found" }, status: :not_found
  end


  def update
    @cart_item = CartItem.find(params[:id])
    if @cart_item.update(quantity: params[:quantity])
      render json: { success: true, message: "Quantity updated", new_quantity: @cart_item.quantity }
    else
      render json: { success: false, message: "Failed to update quantity" }, status: :unprocessable_entity
    end
  end

  def destroy
    @cart_item = CartItem.find(params[:id])
    if @cart_item.destroy
      render json: { success: true, message: "Item removed from cart" }
    else
      render json: { success: false, message: "Failed to remove item" }, status: :unprocessable_entity
    end
  end

  def apply_promotion
    promotion = Promotion.find_by(promote_code: params[:promote_code])

    if promotion.nil?
      render json: { success: false, message: 'Promotion not found' }, status: :not_found
      return
    end

    updated_prices = {}
    case promotion.promotion_type
    when 'product'
      apply_product_discount(promotion, updated_prices)
      render json: { success: true, message: 'You have applied a product discount', updated_prices: updated_prices }
    when 'category'
      apply_category_discount(promotion, updated_prices)
      render json: { success: true, message: 'You have applied a category discount', updated_prices: updated_prices }
    else
      render json: { success: false, message: 'Invalid promotion type' }, status: :unprocessable_entity
    end
  end

  private

  def apply_product_discount(promotion, updated_prices)
    @cart.cart_items.each do |item|
      if item.product_id == promotion.apply_field.to_i
        discount_value = item.price * (promotion.value / 100.0)
        new_price = item.price - discount_value
        new_price = [new_price, 0].max # Ensure price doesn't go below zero
        updated_prices[item.id] = { old_price: item.price * item.quantity, new_price: new_price * item.quantity }
      end
    end
  end

  def apply_category_discount(promotion, updated_prices)
    @cart.cart_items.each do |item|
      if item.product.product_type == promotion.apply_field
        discount_value = item.price * (promotion.value / 100.0)
        new_price = item.price - discount_value
        new_price = [new_price, 0].max
        updated_prices[item.id] = { old_price: item.price * item.quantity, new_price: new_price * item.quantity }
      end
    end
  end

  def set_cart
    @cart = Cart.find(params[:cart_id])
  end
end
