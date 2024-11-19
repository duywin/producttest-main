module UserDelivery
  extend ActiveSupport::Concern

  private

  def build_address
    "#{params[:cart][:street]}, #{params[:cart][:district]}, #{params[:cart][:city]}, #{params[:cart][:country]}"
  end

  def update_stock(cart_id)
    cart_items = CartItem.where(cart_id: cart_id)
    cart_items.each do |item|
      product = item.product
      next unless product.stock

      product.stock -= item.quantity
      product.save
    end
  end
end
