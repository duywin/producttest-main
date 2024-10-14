class CartsController < ApplicationController

  def index
    @carts = Cart.includes(:account).where(check_out: true).page(params[:page])
    @carts = @carts.where(status: params[:status]) if params[:status].present?
  end

  def show
    @cart = Cart.find(params[:id])
    @cart_items = @cart ? CartItem.includes(:product).where(cart_id: @cart.id) : []
  end

  def update_item
    @cart_item = CartItem.find(params[:id])
    if @cart_item.update(quantity: params[:quantity])
      render json: { success: true, message: "Quantity updated", new_quantity: @cart_item.quantity }
    else
      render json: { success: false, errors: @cart_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def checkout
    @cart = Cart.find(params[:id])
    if @cart.cart_items.any?
      reduce_stock(@cart)
      @cart.update(check_out: true)
      flash[:notice] = 'Checkout completed successfully.'
      respond_to do |format|
        format.json { render json: { success: true } }
        format.html { redirect_to delivery_form_path }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, message: 'Cannot checkout an empty cart.' }, status: :unprocessable_entity }
        format.html { redirect_to carts_path, alert: 'Cannot checkout an empty cart.' }
      end
    end
  end

  def apply_cart_promotion
    promotion = Promotion.find_by(promote_code: params[:promote_code])
    cart = Cart.find(params[:cart_id])
    if promotion.nil?
      render json: { success: false, message: 'Promotion not found' }, status: :not_found
      return
    end
    if promotion.promotion_type == 'cart'
      old_total = cart.total_price
      new_total = apply_cart_discount(promotion, cart)
      render json: { success: true, new_total: new_total, old_total: old_total, message: 'Cart promotion applied successfully' }
    else
      render json: { success: false, message: 'Invalid promotion type for cart' }, status: :unprocessable_entity
    end
  end

  private

  def apply_cart_discount(promotion, cart)
    discount_rate = promotion.value / 100.0
    cart_items = cart.cart_items
    old_total = cart_items.sum { |item| item.price * item.quantity }
    new_total = old_total * (1 - discount_rate)
    cart.update(total_price: new_total)
    new_total
  end

  def reduce_stock(cart)
    cart.cart_items.each do |item|
      item.product.update(stock: item.product.stock - item.quantity)
    end
  end

  def cart_params
    params.require(:cart).permit(:username, :check_out, :address, :status, :delivery_day) # Added :status and :delivery_day
  end
end

