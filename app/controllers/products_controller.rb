require_relative '../services/promotion_report_exporter'

# Controller for handling Product-related actions
class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]
  before_action :set_categories, only: %i[new edit create update]
  before_action :authenticate_admin, only: [:index]

  # Redirects non-admin users to noindex_path
  def authenticate_admin
    redirect_to(noindex_path) if session[:current_account_id].nil? && request.path != noindex_path
  end

  # Renders the product index view (for DataTable)
  def index
    # Render the DataTable view for listing products
  end

  # Fetches and returns products data for DataTable
  def render_product_datatable
    query = params[:query].presence
    @products = query.present? ? Product.search(query).records : Product.all

    data = @products.map do |product|
      {
        id: product.id,
        name: product.name,
        prices: product.prices,
        product_type: product.product_type,
        actions: render_product_actions(product)
      }
    end

    render json: { data: data, status: 200 }
  end

  # Fetches and returns promotions data for DataTable
  def render_promotion_datatable
    @promotions = Promotion.all

    data = @promotions.map do |promotion|
      {
        id: promotion.id,
        promote_code: promotion.promote_code,
        promotion_type: promotion.promotion_type.humanize,
        apply_field: promotion.apply_field,
        end_date: promotion.end_date,
        min_quantity: promotion.min_quantity,
        actions: render_promotion_actions(promotion)
      }
    end

    render json: { data: data, status: 200 }
  end

  # Fetches and returns merchandise data for DataTable
  def render_merchandise_datatable
    @merchandises = Merchandise.all

    data = @merchandises.map do |merchandise|
      {
        id: merchandise.id,
        product_id: merchandise.product_id,
        cut_off_value: merchandise.cut_off_value,
        promotion_end: merchandise.promotion_end.present? ? merchandise.promotion_end.strftime("%Y-%m-%d") : 'N/A',
        actions: render_merchandise_actions(merchandise)
      }
    end

    render json: { data: data, status: 200 }
  end

  # Handles report generation and export (weekly/monthly)
  def export_report
    allowed_report_types = ['weekly', 'monthly']
    report_type = params[:report_type]

    unless allowed_report_types.include?(report_type)
      return redirect_to(products_path, alert: 'Invalid report type.')
    end

    filename = generate_report(report_type)

    if filename.nil? || !File.exist?(file_path = Rails.root.join('tmp', filename))
      return redirect_to(products_path, alert: 'Failed to generate or export the report.')
    end

    send_file(file_path, type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', disposition: 'attachment')
  end

  # Displays details of a specific product, including related promotions and sold quantities
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

  # Initializes a new product object for creation
  def new
    @product = Product.new
  end

  # Handles file import for products (ODS file)
  def import
    uploaded_file = params[:file]

    unless uploaded_file && uploaded_file.content_type == 'application/vnd.oasis.opendocument.spreadsheet'
      return redirect_to(products_path, alert: 'Please upload a valid ODS file.')
    end

    file_path = Rails.root.join('tmp', uploaded_file.original_filename)
    File.open(file_path, 'wb') { |file| file.write(uploaded_file.read) }

    ProductImportJob.perform_async(file_path.to_s)
    product_logger.info("Product import started for file '#{uploaded_file.original_filename}' by Account ID #{session[:current_account_id]}")

    redirect_to(products_path, notice: 'Product import has started. You will be notified once complete.')
  end

  # Creates a new product record in the database
  def create
    @product = Product.new(product_params)
    set_default_values(@product)

    if @product.save
      product_logger.info("Product created: ID '#{@product.id}', Name '#{@product.name}'", session[:current_account_id])
      redirect_to(@product, notice: 'Product was successfully created.')
    else
      product_logger.error("Failed to create product: #{@product.errors.full_messages.join(', ')}", session[:current_account_id])
      render(:new, status: :unprocessable_entity)
    end
  end

  # Displays the form to edit an existing product
  def edit; end

  # Updates an existing product record in the database
  def update
    if params[:product][:picture].present?
      @product.picture = params[:product][:picture]
    elsif params[:product][:picture_file].present?
      @product.picture_file = params[:product][:picture_file]
    end

    if @product.update(product_params)
      redirect_to(@product, notice: 'Product was successfully updated.')
    else
      render(:edit, status: :unprocessable_entity)
    end
  end

  # Destroys a product record from the database
  def destroy
    if @product.destroy
      product_logger.info("Product destroyed: ID '#{@product.id}', Name '#{@product.name}'", session[:current_account_id])
      redirect_to(products_path, notice: 'Product was successfully destroyed.')
    else
      product_logger.error("Failed to destroy product: #{@product.errors.full_messages.join(', ')}", session[:current_account_id])
      redirect_to(products_path, alert: 'Failed to destroy the product.')
    end
  end

  private

  # Sets the @product instance variable for show, edit, update, destroy actions
  def set_product
    @product = Product.find(params[:id])
  end

  # Strong parameter method for product input validation
  def product_params
    params.require(:product).permit(:name, :prices, :product_type, :stock, :desc, :picture, :picture_file)
  end

  # Sets the categories available for product selection
  def set_categories
    @categories = Category.pluck(:name)
  end

  # Generates report filename based on report type (weekly/monthly)
  def generate_report(report_type)
    case report_type
    when 'weekly'
      PromotionReportExporter.export_weekly_report
    when 'monthly'
      PromotionReportExporter.export_monthly_report
    end
  end

  # Sets default values for new products if not provided
  def set_default_values(product)
    product.desc ||= 'No description available.'
    product.stock ||= 0
    product.picture ||= 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRfCIpb4DjTLc26hfSl7YKW6bf07zz38YcyHQ&s'
  end

  # Helper method to log product-related actions
  def product_logger
    @product_logger ||= MonthLogger.new(Product)
  end

  # Generates HTML actions for products (view, edit, delete)
  def render_product_actions(product)
    %(
      <div class="d-flex gap-3 align-items-center">
        <button type="button" onclick="window.location='#{product_path(product)}'" class="btn btn-primary" style="color: white; padding: 8px 16px; border-radius: 4px; border: none; cursor: pointer; background: none; font-size: 18px;" title="View Details">
          <span>👁</span>
        </button>
        <button type="button" onclick="window.location='#{edit_product_path(product)}'" class="btn btn-primary" style="color: blue; padding: 8px 16px; border-radius: 4px; border: none; cursor: pointer; background: none; font-size: 18px;" title="Edit Product">
          <span>✎</span>
        </button>
        <button type="button" data-method="delete" data-confirm="Are you sure?" class="btn btn-danger delete-product-btn" data-product-id="#{product.id}" style="background: none; padding: 8px 16px; border-radius: 4px; border: none; color: red; cursor: pointer; font-size: 18px;" title="Delete Product">
          <span>❌</span>
        </button>
      </div>
    )
  end

  # Generates HTML actions for promotions (delete)
  def render_promotion_actions(promotion)
    %(
      <div class="d-flex gap-2 align-items-center">
        <button type="button" data-method="delete" data-confirm="Are you sure?" class="btn btn-danger delete-promotion-btn" data-promotion-id="#{promotion.id}" style="background: none; padding: 8px 16px; border-radius: 4px; border: none; color: red; cursor: pointer; font-size: 18px;">
          <span>❌</span>
        </button>
      </div>
    )
  end

  # Generates HTML actions for merchandise (delete)
  def render_merchandise_actions(merchandise)
    %(
      <div class="d-flex gap-2 align-items-center">
        <button type="button" data-method="delete" data-confirm="Are you sure?" class="btn btn-danger delete-merchandise-btn" data-merchandise-id="#{merchandise.id}" style="background: none; padding: 8px 16px; border-radius: 4px; border: none; color: red; cursor: pointer; font-size: 18px;">
          <span>❌</span>
        </button>
      </div>
    )
  end

end
