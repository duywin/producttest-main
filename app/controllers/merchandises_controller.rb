# app/controllers/merchandises_controller.rb
class MerchandisesController < ApplicationController
  # GET /merchandises
  def index
    @merchandises = Merchandise.all
  end

  def create
    @merchandise = Merchandise.new(merchandise_params)
    if @merchandise.save
      # Log merchandise creation
      merch_logger.info("Merchandise created: Product ID '#{@merchandise.product_id}', Cut Off Value '#{@merchandise.cut_off_value}', Promotion End '#{@merchandise.promotion_end}'", session[:current_account_id])
      redirect_to(products_path, notice: 'Merchandise created successfully!')
    else
      render(:new, status: :unprocessable_entity)
    end
  end


  def destroy
    @merchandise = Merchandise.find(params[:id])
    product_id = @merchandise.product_id
    @merchandise.destroy

    merch_logger.info("Merchandise deleted: Product ID '#{product_id}'", session[:current_account_id])
    redirect_to(products_path, notice: 'Merchandise deleted successfully!')
  end

  private

  # Strong parameters for Merchandise
  def merchandise_params
    params.require(:merchandise).permit(:product_id, :cut_off_value, :promotion_end)
  end

  # Initializes the logger for merchandise actions
  def merch_logger
    @merch_logger ||= MonthLogger.new(Merchandise)
  end
end
