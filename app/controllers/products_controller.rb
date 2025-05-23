require_relative '../services/promotion_report_exporter'
class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :set_categories, only: [:new, :edit, :create, :update]
  before_action :authenticate_admin, only: [:index]

  def authenticate_admin
    if session[:current_account_id].nil?
      unless request.path == noindex_path # Ensure we aren't redirecting in a loop
        redirect_to noindex_path
      end
    end
  end
  def index
    @q = Product.ransack(params[:q])
    @products = @q.result.page(params[:page]).per(10)  # Kaminari pagination with 10 items per page
    @promotions = Promotion.all.page(params[:promotion_page]).per(5)
    @merchandises = Merchandise.all.page(params[:merchant_page]).per(5)
  end

  def export_report
    report_type = params[:report_type]
    exporter = PromotionReportExporter.new

    # Determine which report to export
    case report_type
    when 'weekly'
      filename = exporter.export_weekly_report
    when 'monthly'
      filename = exporter.export_monthly_report
    else
      redirect_to products_path, alert: "Invalid report type."
      return
    end

    if filename
      send_file "#{filename}.xlsx", type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", disposition: 'attachment'
    else
      redirect_to products_path, alert: "Failed to export the report."
    end
  end



  def show
    @promotions = Promotion.joins(:promote_products).where(promote_products: { product_id: @product.id })
  end

  def new
    @product = Product.new
  end

  def import
    file = params[:file]
    if file.nil?
      redirect_to categories_path, alert: 'Please upload an ODS file.'
      return
    end

    products = []

    # Read the ODS file
    begin
      spreadsheet = Roo::OpenOffice.new(file.path)

      # Assuming the first row is the header
      header = spreadsheet.row(1)

      # Define the default values for the product attributes
      default_values = {
        desc: "No description available.",
        stock: 0,
        picture: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRfCIpb4DjTLc26hfSl7YKW6bf07zz38YcyHQ&s"
      }

      # Start from the second row to skip the header
      (2..spreadsheet.last_row).each do |i|
        row = spreadsheet.row(i)

        # Use the header index to find values; if not found, use default values
        name = row[header.index('name')] || default_values[:name]
        product_type = row[header.index('product_type')] || "Default Type"
        prices = row[header.index('prices')] || 0.00
        desc = row[header.index('desc')] || default_values[:desc]
        stock = row[header.index('stock')] || default_values[:stock]
        picture = row[header.index('picture')] || default_values[:picture]

        # Only create the product if a name is present
        if name.present?
          products << Product.new(
            name: name,
            product_type: product_type,
            prices: prices,
            desc: desc,
            stock: stock,
            picture: picture
          )
        end
      end

    rescue => e
      redirect_to products_path, alert: "Error reading file: #{e.message}"
      return
    end

    Product.import(products)
    redirect_to products_path, notice: 'Products were successfully imported.'
  end

  def create
    # Set default values for fields not provided
    @product = Product.new(product_params)
    @product.desc ||= "No description available."
    @product.stock ||= 0
    @product.picture ||= "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRfCIpb4DjTLc26hfSl7YKW6bf07zz38YcyHQ&s"

    if @product.save
      redirect_to @product, notice: 'Product was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: 'Product was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: 'Product was successfully destroyed.'
  end

  private
  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :prices, :product_type, :stock, :desc, :picture)
  end

  def set_categories
    @categories = Category.pluck(:name)
  end
end
