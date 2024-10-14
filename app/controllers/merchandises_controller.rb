class MerchandisesController < ApplicationController

  def index
    @merchandises = Merchandise.all
  end

  def create
    @merchandise = Merchandise.new(merchandise_params)
    if @merchandise.save
      redirect_to products_path, notice: 'Merchandise created successfully!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @merchandise = Merchandise.find(params[:id])
    @merchandise.destroy
    redirect_to products_path, notice: 'Promotion deleted successfully!'
  end
  private

  def merchandise_params
    # Permit the necessary parameters for Merchandise
    params.require(:merchandise).permit(:product_id, :cut_off_value, :promotion_end)
  end
end
