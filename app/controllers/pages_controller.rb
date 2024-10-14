class PagesController < ApplicationController
  before_action :set_account, only: [:userhome, :aboutus, :delivery_form,
                                     :myaccount, :shop, :shop_cart,]

  def userhome
    @random_products = Product.order('RAND()').limit(5)
  end

  def aboutus
  end

  def shop
    @products = Product.all
    if @account
      @cart = Cart.where(account_id: @account.id).where(check_out: false).first_or_create
      session[:cart_id] = @cart.id
      @cart_item_count = @cart.cart_items.count
    end

    # Filter by search query
    if params[:search].present?
      @products = @products.where('name LIKE ?', "%#{params[:search]}%")
    end

    # Filter by product type
    if params[:product_type].present?
      @products = @products.where(product_type: params[:product_type])
    end

    # Filter by price range
    if params[:price_min].present?
      @products = @products.where('prices >= ?', params[:price_min].to_f)
    end
    if params[:price_max].present?
      @products = @products.where('prices <= ?', params[:price_max].to_f)
    end

    # Add pagination (6 products per page)
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
      if @cart_items.present?
        @cart.total_price = @cart_items.sum { |item| item.product.prices.to_f * item.quantity }
        @cart.quantity = @cart_items.sum(&:quantity)
        @cart.check_out = false
        @cart.save
      end
      @cart_id = @cart.id if @cart
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
    if @cart
      address = "#{params[:cart][:street]}, #{params[:cart][:district]}, #{params[:cart][:city]}, #{params[:cart][:country]}"
      @cart.update(address: address, status: 'pending')

      if @cart.save
        update_stock(@cart.id)
        redirect_to users_home_path, notice: 'Delivery details updated successfully.'
      else
        flash.now[:alert] = 'Failed to update delivery details.'
        render :delivery_form
      end
    else
      redirect_to shop_cart_path, alert: 'Cart not found.'
    end
  end


  def myaccount
    @edit_mode = false
    @carts = Cart.where(account_id: @account.id).where(check_out: true)
  end

  def update_account
    @account = Account.find(params[:id])
    if @account.update(account_params)
      respond_to do |format|
        format.js
      end
    else
      respond_to do |format|
        format.js { render 'update_failed' }
      end
    end
  end
  def delivery_history
    @carts = Cart.where(account_id: session[:current_account_id]).where(check_out: true)
  end
  
  def logout
    session.delete(:current_account_id) if session[:current_account_id]
    redirect_to users_home_path
  end

  private

  def update_stock(cart_id)
    cart_items = CartItem.where(cart_id: cart_id)

    cart_items.each do |item|
      product = Product.find(item.product_id)
      if product.stock.present? # Ensure stock is present
        product.stock -= item.quantity
        product.save # Save the product with updated stock
      end
    end
  end

  def set_account
    @account = Account.find_by(id: session[:current_account_id])
  end
end
