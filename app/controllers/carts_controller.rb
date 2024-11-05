class CartsController < ApplicationController
  def index
    @weeks = Cart.fetch_weeks_with_checkouts
  end

  def render_cart_datatable
    search_params = params.permit(:week, :day, :sort_order, :status)
    es_results = Cart.search_carts(search_params)
    cart_ids = es_results.map(&:id)
    @carts = Cart.includes(:account).checked_out.where(id: cart_ids)

    data = @carts.map(&:formatted_data)
    render json: { data: data, status: 200 }
  end
  def edit
    @cart = Cart.find(params[:id])
  end

  def update
    @cart = Cart.find(params[:id])
    if @cart.update(cart_params)
      @cart.admin_update = true
      redirect_to carts_path, notice: "Cart was successfully updated."
      month_logger.info("Cart updated: '#{@cart.id}' by user '#{session[:current_account_id]}'", session[:current_account_id])
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @cart = Cart.find(params[:id]) #show a
    @cart_items = @cart ? CartItem.includes(:product).where(cart_id: @cart.id) : []
  end

  def update_item
    @cart_item = CartItem.find(params[:id])
    if @cart_item.update(quantity: params[:quantity])
      render json: {
        success: true,
        message: "Quantity updated",
        new_quantity: @cart_item.quantity
      }
    else
      render json: {
        success: false,
        errors: @cart_item.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def checkout
    @cart = Cart.find(params[:id])

    if @cart.cart_items.any?
      reduce_stock(@cart)
      @cart.update(check_out: true)
      @cart.function_check_out = true
      flash[:notice] = "Checkout completed successfully."
      month_logger.info("Cart checked out: '#{@cart.id}' by user '#{session[:current_account_id]}'", session[:current_account_id])


      respond_to do |format|
        format.json { render json: { success: true } }
        format.html { redirect_to delivery_form_path, notice: flash[:notice] }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, message: "Cannot checkout an empty cart." }, status: :unprocessable_entity }
        format.html { redirect_to carts_path, alert: "Cannot checkout an empty cart." }
      end
    end
  end

  def apply_cart_promotion
    promotion = Promotion.find_by(promote_code: params[:promote_code])
    cart = Cart.find(params[:cart_id])

    unless promotion
      render json: { success: false, message: "Promotion not found" }, status: :not_found
      return
    end

    if promotion.promotion_type == "cart"
      old_total = cart.total_price
      new_total = apply_cart_discount(promotion, cart)
      render json: {
        success: true,
        new_total: new_total,
        old_total: old_total,
        message: "Cart promotion applied successfully"
      }
    else
      render json: { success: false, message: "Invalid promotion type for cart" }, status: :unprocessable_entity
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
    params.require(:cart).permit(
      :username,
      :check_out,
      :address,
      :status,
      :delivery_day)
  end
  def month_logger
    @month_logger ||= MonthLogger.new(Cart)
  end
end







