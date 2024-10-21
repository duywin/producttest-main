class PromotionsController < ApplicationController
  before_action :set_promotion, only: [:destroy]

  # Displays all promotions.
  def index
    @promotions = Promotion.all
  end

  # Initializes a new promotion and merchandise.
  def new
    @promotion = Promotion.new
    @merchandise = Merchandise.new
  end

  # Creates a new promotion and applies promotion logic.
  def create
    @promotion = Promotion.new(promotion_params)
    if @promotion.save
      apply_promotion_logic(@promotion)
      redirect_to products_path, notice: "Promotion created successfully!"
    else
      render :new
    end
  end

  # Destroys a promotion and associated promote products.
  def destroy
    PromoteProduct.where(promotion_id: @promotion.id).destroy_all
    @promotion.destroy
    redirect_to products_path, notice: "Promotion deleted successfully!"
  end

  # Checks the type of promotion based on the promotion code.
  def check_type
    promotion = Promotion.find_by(promote_code: params[:promote_code])
    if promotion
      render json: { success: true, promotion_type: promotion.promotion_type }
    else
      render json: { success: false, message: "Invalid promotion code" }, status: :not_found
    end
  end

  private

  # Strong parameters for promotion.
  def promotion_params
    params.require(:promotion).permit(:promote_code, :promotion_type, :apply_field, :value, :end_date, :min_quantity)
  end

  # Sets the promotion based on the ID parameter.
  def set_promotion
    @promotion = Promotion.find(params[:id])
  end

  # Applies the promotion logic based on promotion type.
  def apply_promotion_logic(promotion)
    case promotion.promotion_type
    when "product"
      product = Product.find_by(id: params[:promotion][:apply_field])
      if product
        create_promote_product(promotion.id, product.id, 1000)
      else
        flash[:alert] = "Product not found"
      end
    when "category"
      products = Product.where(product_type: params[:promotion][:apply_field])
      products.each { |product| create_promote_product(promotion.id, product.id, 300) }
    when "cart"
      # No promote-product record for cart promotion
    end
  end

  # Creates a promote product record.
  def create_promote_product(promotion_id, product_id, value)
    PromoteProduct.create!(promotion_id: promotion_id, product_id: product_id, amount: value)
  end
end