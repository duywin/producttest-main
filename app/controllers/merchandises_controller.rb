# Controller for handling Merchandise-related actions
class MerchandisesController < ApplicationController
  # GET /merchandises
  def index
    @merchandises = Merchandise.all
  end

  # POST /merchandises
  def create
    @merchandise = Merchandise.new(merchandise_params)
    if @merchandise.save
      redirect_to(products_path, notice: 'Merchandise created successfully!')
    else
      render(:new, status: :unprocessable_entity)
    end
  end

  # DELETE /merchandises/:id
  def destroy
    @merchandise = Merchandise.find(params[:id])
    @merchandise.destroy
    redirect_to(products_path, notice: 'Merchandise deleted successfully!')
  end

  private

  # Strong parameters for Merchandise
  def merchandise_params
    params.require(:merchandise).permit(:product_id, :cut_off_value, :promotion_end)
  end
end