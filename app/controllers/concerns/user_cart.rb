module UserCart
  extend ActiveSupport::Concern

  private

  def setup_cart
    return unless @account

    @cart = Cart.where(account_id: @account.id, check_out: false).first_or_create
    session[:cart_id] = @cart.id
    @cart_item_count = @cart.cart_items.count
  end

  def update_cart
    return unless @cart

    @cart.total_price = @cart.cart_items.sum { |item| item.product.prices.to_f * item.quantity }
    @cart.quantity = @cart.cart_items.sum(&:quantity)
    @cart.check_out = false
    @cart.save
  end

  def filter_products
    @products = @products.where('name LIKE ?', "%#{params[:search]}%") if params[:search].present?
    @products = @products.where(product_type: params[:product_type]) if params[:product_type].present?
    @products = @products.where('prices >= ?', params[:price_min].to_f) if params[:price_min].present?
    @products = @products.where('prices <= ?', params[:price_max].to_f) if params[:price_max].present?
  end
end
