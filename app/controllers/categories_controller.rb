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
        render json: { data: Category.all.as_json(only: [:name, :total, :id]) }
      end
    end
  end

  # Authenticates the admin by checking if the current account ID is present.
  def authenticate_admin
    redirect_to noindex_path if session[:current_account_id].nil? && request.path != noindex_path
  end

  # Refreshes the total count for each category.
  def refreshtotal
    Category.find_each { |category| category.update(total: Product.where(product_type: category.name).count) }
    redirect_to categories_path, notice: "Total counts refreshed successfully."
  end

  # Imports categories from an ODS file.
  def import
    file = params[:file]
    if file.nil?
      redirect_to categories_path, alert: "Please upload an ODS file."
      return
    end

    file_path = save_temp_file(file)
    ImportCategoriesJob.perform_async(file_path)

    month_logger.info("Import started for file '#{file.original_filename}'", session[:current_account_id])
    redirect_to categories_path, notice: "File read successfully. Please wait for the import."
  end

  # Initializes a new category.
  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    @category.total ||= 0

    if @category.save
      month_logger.info("Category '#{@category.name}' (ID: #{@category.id}) was created", session[:current_account_id])
      redirect_to categories_path, notice: "Category was successfully created."
    else
      redirect_to categories_path, alert: "Unable to create category"
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

  # Saves the uploaded file temporarily and returns the file path.
  def save_temp_file(file)
    file_path = Rails.root.join("tmp", "uploads", file.original_filename)
    FileUtils.mkdir_p(file_path.dirname)
    File.open(file_path, "wb") { |f| f.write(file.read) }
    file_path.to_s
  end
end
