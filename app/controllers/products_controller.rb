require_relative '../services/promotion_report_exporter'

# Controller for handling Product-related actions
class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]
  before_action :set_categories, only: %i[new edit create update]
  before_action :authenticate_admin, only: [:index]

  def authenticate_admin
    return unless session[:current_account_id].nil?
    redirect_to(noindex_path) unless request.path == noindex_path
  end

  def index
    @products = search_products
    @promotions = Promotion.all.page(params[:promotion_page]).per(5)
    @merchandises = Merchandise.all.page(params[:merchant_page]).per(5)
  end

  def export_report
    # Define a list of allowed report types
    allowed_report_types = ['summary', 'detailed'] # Adjust based on actual report types

    # Sanitize and validate the report_type parameter
    report_type = params[:report_type]

    unless allowed_report_types.include?(report_type)
      return redirect_to(products_path, alert: 'Invalid report type.')
    end

    # Generate the report filename based on the validated report_type
    filename = generate_report(report_type)

    # Check if the filename is valid
    return redirect_to(products_path, alert: 'Invalid report type.') if filename.nil?
    file_path = Rails.root.join('tmp', filename)

    # Check if the file exists before sending
    if File.exist?(file_path)
      send_file(file_path,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment')
    else
      redirect_to(products_path, alert: 'Failed to export the report.')
    end
  end

  def show
    @product = Product.find(params[:id])
    @promotions = Promotion.joins(:promote_products).where(promote_products: { product_id: @product.id })
    @merchandises = Merchandise.where(product_id: @product.id)

    # Calculate sold merchandise quantities and store in a hash
    @sold_quantities = {}

    @merchandises.each do |merchandise|
      discount_price = merchandise.product.prices * (1 - (merchandise.cut_off_value / 100.0))
      sold_quantity = CartItem.where(
        product_id: merchandise.product_id,
        price: discount_price
      ).sum(:quantity)

      @sold_quantities[merchandise.id] = sold_quantity
    end
  end
  def new
    @product = Product.new
  end

  def import
    return redirect_to(categories_path, alert: 'Please upload an ODS file.') if params[:file].nil?

    products = import_products_from_file(params[:file])
    if products.is_a?(String)
      redirect_to(products_path, alert: products)
    else
      Product.import(products)
      redirect_to(products_path, notice: 'Products were successfully imported.')
    end
  end

  def create
    @product = Product.new(product_params)
    set_default_values(@product)

    if @product.save
      redirect_to(@product, notice: 'Product was successfully created.')
    else
      render(:new, status: :unprocessable_entity)
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to(@product, notice: 'Product was successfully updated.')
    else
      render(:edit, status: :unprocessable_entity)
    end
  end

  def destroy
    @product.destroy
    redirect_to(products_path, notice: 'Product was successfully destroyed.', status: :see_other)
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

  def search_products
    query = params[:query].presence
    if query.present?
      Product.search(query).records.page(params[:page]).per(10)
    else
      Product.all.page(params[:page]).per(10)
    end
  end

  def generate_report(report_type)
    case report_type
    when 'weekly'
      PromotionReportExporter.export_weekly_report
    when 'monthly'
      PromotionReportExporter.export_monthly_report
    end
  end

  def import_products_from_file(file)
    spreadsheet = Roo::OpenOffice.new(file.path)
    header = spreadsheet.row(1)
    products = []

    (2..spreadsheet.last_row).each do |i|
      row = spreadsheet.row(i)
      product = create_product_from_row(row, header)
      products << product if product.name.present?
    end

    products
  rescue StandardError => e
    "Error reading file: #{e.message}"
  end

  def create_product_from_row(row, header)
    default_values = {
      desc: 'No description available.',
      stock: 0,
      picture: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRfCIpb4DjTLc26hfSl7YKW6bf07zz38YcyHQ&s'
    }

    Product.new(
      name: row[header.index('name')] || default_values[:name],
      product_type: row[header.index('product_type')] || 'Default Type',
      prices: row[header.index('prices')] || 0.00,
      desc: row[header.index('desc')] || default_values[:desc],
      stock: row[header.index('stock')] || default_values[:stock],
      picture: row[header.index('picture')] || default_values[:picture]
    )
  end

  def set_default_values(product)
    product.desc ||= 'No description available.'
    product.stock ||= 0
    product.picture ||= 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRfCIpb4DjTLc26hfSl7YKW6bf07zz38YcyHQ&s'
  end
end