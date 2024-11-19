class CartsController < ApplicationController
  before_action :set_cart, only: [:edit, :update, :show, :checkout]

  # Displays all weeks with checkouts.
  def index
    @weeks = Cart.fetch_weeks_with_checkouts
  end

  # Renders cart datatable with filtered search results.
  def render_cart_datatable
    search_params = params.permit(:week, :day, :sort_order, :status)
    cart_ids = Cart.search_carts(search_params).map(&:id)
    @carts = Cart.includes(:account).checked_out.where(id: cart_ids)

    render json: { data: @carts.map(&:formatted_data), status: 200 }
  end

  # Displays the cart edit form.
  def edit; end

  # Updates cart attributes.
  def update
    if @cart.update(cart_params)
      @cart.admin_update = true
      month_logger.info("Cart updated: '#{@cart.id}' by user '#{session[:current_account_id]}'", session[:current_account_id])
      redirect_to carts_path, notice: "Cart was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Shows a specific cart and its items.
  def show
    @cart_items = @cart ? CartItem.includes(:product).where(cart_id: @cart.id) : []
  end

  # Updates the quantity of a cart item.
  def update_item
    cart_item = CartItem.find(params[:id])
    if cart_item.update(quantity: params[:quantity])
      render json: { success: true, message: "Quantity updated", new_quantity: cart_item.quantity }
    else
      render json: { success: false, errors: cart_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Handles cart checkout.
  def checkout
    if @cart.cart_items.any?
      reduce_stock(@cart)
      @cart.update(check_out: true, function_check_out: true)
      log_checkout

      respond_to do |format|
        format.json { render json: { success: true } }
        format.html { redirect_to delivery_form_path, notice: "Checkout completed successfully." }
      end
    else
      handle_empty_cart
    end
  end

  # Applies a cart promotion.
  def apply_cart_promotion
    promotion = Promotion.find_by(promote_code: params[:promote_code])
    cart = Cart.find(params[:cart_id])

    if promotion&.promotion_type == "cart"
      render json: cart_promotion_success(promotion, cart)
    else
      render json: { success: false, message: promotion ? "Invalid promotion type for cart" : "Promotion not found" }, status: :unprocessable_entity
    end
  end

  private

  # Sets the cart based on the ID parameter.
  def set_cart
    @cart = Cart.find(params[:id])
  end

  # Applies the discount to the cart total price.
  def apply_cart_discount(promotion, cart)
    discount_rate = promotion.value / 100.0
    old_total = cart.cart_items.sum { |item| item.price * item.quantity }
    new_total = old_total * (1 - discount_rate)
    cart.update(total_price: new_total)
    new_total
  end

  # Reduces the stock for each product in the cart.
  def reduce_stock(cart)
    cart.cart_items.each do |item|
      item.product.decrement!(:stock, item.quantity)
    end
  end

  # Strong parameters for cart attributes.
  def cart_params
    params.require(:cart).permit(:username, :check_out, :address, :status, :deliver_day)
  end

  # Logs cart checkout actions.
  def log_checkout
    month_logger.info("Cart checked out: '#{@cart.id}' by user '#{session[:current_account_id]}'", session[:current_account_id])
  end

  # Handles the case where the cart is empty during checkout.
  def handle_empty_cart
    message = "Cannot checkout an empty cart."
    respond_to do |format|
      format.json { render json: { success: false, message: message }, status: :unprocessable_entity }
      format.html { redirect_to carts_path, alert: message }
    end
  end

  # Success response for cart promotion application.
  def cart_promotion_success(promotion, cart)
    old_total = cart.total_price
    new_total = apply_cart_discount(promotion, cart)
    {
      success: true,
      new_total: new_total,
      old_total: old_total,
      message: "Cart promotion applied successfully"
    }
  end

  # Logger for cart actions.
  def month_logger
    @month_logger ||= MonthLogger.new(Cart)
  end
end
