class MerchandisesController < ApplicationController
  before_action :set_merchandise, only: [:destroy]

  # GET /merchandises

  # Creates a new merchandise record.
  def create
    @merchandise = Merchandise.new(merchandise_params)
    if @merchandise.save
      log_merchandise_creation(@merchandise)
      redirect_to(products_path, notice: 'Merchandise created successfully!')
    else
      redirect_to(new_promotion_path, notice: 'Unable to create merchandise, please check the input')
    end
  end

  # Destroys a merchandise record.
  def destroy
    product_id = @merchandise.product_id
    @merchandise.destroy
    log_merchandise_deletion(product_id)
    redirect_to(products_path, notice: 'Merchandise deleted successfully!')
  end

  private

  # Sets the merchandise based on the ID parameter.
  def set_merchandise
    @merchandise = Merchandise.find(params[:id])
  end

  # Strong parameters for Merchandise.
  def merchandise_params
    params.require(:merchandise).permit(:product_id, :cut_off_value, :promotion_end, :promotion_start)
  end

  # Logs merchandise creation.
  def log_merchandise_creation(merchandise)
    merch_logger.info("Merchandise created: Product ID '#{merchandise.product_id}', Cut Off Value '#{merchandise.cut_off_value}', Promotion End '#{merchandise.promotion_end}'", session[:current_account_id])
  end

  # Logs merchandise deletion.
  def log_merchandise_deletion(product_id)
    merch_logger.info("Merchandise deleted: Product ID '#{product_id}'", session[:current_account_id])
  end

  # Logger for merchandise actions.
  def merch_logger
    @merch_logger ||= MonthLogger.new(Merchandise)
  end
end
