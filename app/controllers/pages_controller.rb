# Controller for handling various pages and user actions
class PagesController < ApplicationController
  before_action :set_account, only: %i[userhome aboutus delivery_form myaccount shop shop_cart]

  def userhome
    @random_products = Product.order('RAND()').limit(5)
  end

  def aboutus;
  end

  def shop
    @products = Product.all
    setup_cart if @account
    filter_products
    @products = @products.page(params[:page]).per(6)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def shop_cart
    if @account
      @cart = Cart.find_by(id: session[:cart_id])
      @cart_items = @cart ? CartItem.includes(:product).where(cart_id: @cart.id) : []
      update_cart if @cart_items.present?
      @cart_id = @cart&.id
    else
      @cart_items = []
      @cart_id = nil
    end
  end

  def delivery_form
    @cart = Cart.find_by(id: session[:cart_id])
  end

  def update_delivery
    @cart = Cart.find_by(id: session[:cart_id])
    return redirect_to(shop_cart_path, alert: 'Cart not found.') unless @cart

    address = build_address
    @cart.update(address: address, status: 'pending')

    if @cart.save
      update_stock(@cart.id)
      redirect_to(users_home_path, notice: 'Delivery details updated successfully.')
    else
      flash.now[:alert] = 'Failed to update delivery details.'
      render(:delivery_form)
    end
  end

  def myaccount
    @edit_mode = false
    @carts = Cart.where(account_id: @account.id, check_out: true)
  end

  def update_account
    @account = Account.find(params[:id])
    if @account.update(account_params)
      month_logger.info("Account update (ID: #{session[:current_account_id]})", session[:current_account_id])
      respond_to { |format| format.js }
    else
      respond_to { |format| format.js { render('update_failed') } }
    end
  end

  def delivery_history
    @carts = Cart.where(account_id: session[:current_account_id], check_out: true)
  end

  def logout
    month_logger.info("Account logged out (ID: #{session[:current_account_id]})", session[:current_account_id])
    session.delete(:current_account_id)
    redirect_to(users_home_path)
  end

  private

  def update_stock(cart_id)
    cart_items = CartItem.where(cart_id: cart_id)
    cart_items.each do |item|
      product = item.product
      next unless product.stock
      product.stock -= item.quantity
      product.save
    end
  end

  def set_account
    @account = Account.find_by(id: session[:current_account_id])
  end

  def setup_cart
    @cart = Cart.where(account_id: @account.id, check_out: false).first_or_create
    session[:cart_id] = @cart.id
    @cart_item_count = @cart.cart_items.count
  end

  def filter_products
    @products = @products.where('name LIKE ?', "%#{params[:search]}%") if params[:search].present?
    @products = @products.where(product_type: params[:product_type]) if params[:product_type].present?
    @products = @products.where('prices >= ?', params[:price_min].to_f) if params[:price_min].present?
    @products = @products.where('prices <= ?', params[:price_max].to_f) if params[:price_max].present?
  end

  def update_cart
    @cart.total_price = @cart_items.sum { |item| item.product.prices.to_f * item.quantity }
    @cart.quantity = @cart_items.sum(&:quantity)
    @cart.check_out = false
    @cart.save
  end

  def build_address
    "#{params[:cart][:street]}, #{params[:cart][:district]}, #{params[:cart][:city]}, #{params[:cart][:country]}"
  end

  def account_params
    # Add the necessary permitted parameters here
    params.require(:account).permit(:name, :email)
  end

  def month_logger
    @month_logger ||= MonthLogger.new(Account)
  end
end