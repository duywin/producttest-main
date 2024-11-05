# app/controllers/categories_controller.rb
class CategoriesController < ApplicationController
  before_action :set_category, only: [:destroy]
  before_action :authenticate_admin

  # Displays a paginated list of categories.
  def index
    respond_to do |format|
      format.html do
        @categories = Category.page(params[:page])
        @category = Category.new
      end
      format.json do
        @categories = Category.all
        render json: { data: @categories.as_json(only: [:name, :total, :id]) }
      end
    end
  end

  # Authenticates the admin by checking if the current account ID is present.
  def authenticate_admin
    if session[:current_account_id].nil? && request.path != noindex_path
      redirect_to noindex_path
    end
  end

  # Refreshes the total count for each category.
  def refreshtotal
    Category.find_each do |category|
      total_count = Product.where(product_type: category.name).count
      category.update(total: total_count)
    end
    redirect_to categories_path, notice: "Total counts refreshed successfully."
  end

  # Imports categories from an ODS file.
  def import
    file = params[:file]

    if file.nil?
      redirect_to categories_path, alert: "Please upload an ODS file."
      return
    end

    # Save the file temporarily
    file_path = Rails.root.join("tmp", "uploads", file.original_filename)
    FileUtils.mkdir_p(file_path.dirname)
    File.open(file_path, "wb") { |f| f.write(file.read) }

    ImportCategoriesJob.perform_later(file_path.to_s)
    month_logger.info("Import started for file '#{file.original_filename}'", session[:current_account_id])

    redirect_to categories_path, notice: "File read successfully. Please wait for the import"
  end

  # Initializes a new category.
  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    @category.total ||= 0

    if @category.save
      # Log the add action
      month_logger.info("Category '#{@category.name}' (ID: #{@category.id}) was created", session[:current_account_id])
      redirect_to categories_path, notice: "Category was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Deletes the specified category.
  def destroy
    @category.destroy
    month_logger.warn("Category '#{@category.name}' (ID: #{@category.id}) was deleted", session[:current_account_id])
    redirect_to categories_path, notice: "Category was successfully deleted."
  end

  private

  # Sets the category based on the ID parameter.
  def set_category
    @category = Category.find(params[:id])
  end

  # Permits category parameters.
  def category_params
    params.require(:category).permit(:id, :name, :total)
  end

  # Initializes the monthly logger for this controller.
  def month_logger
    @month_logger ||= MonthLogger.new(Category)
  end
end
