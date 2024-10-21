class CategoriesController < ApplicationController
  before_action :set_category, only: [:destroy]
  before_action :authenticate_admin

  # Authenticates the admin by checking if the current account ID is present.
  # Redirects to noindex_path if not authenticated, avoiding redirect loops.
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

    categories = []

    begin
      spreadsheet = Roo::OpenOffice.new(file.path)
      header = spreadsheet.row(1)

      (2..spreadsheet.last_row).each do |i|
        row = spreadsheet.row(i)
        name = row[header.index("name")]
        categories << Category.new(name: name, total: 0) if name.present?
      end
    rescue => e
      redirect_to categories_path, alert: "Error reading file: #{e.message}"
      return
    end

    Category.import(categories)
    redirect_to categories_path, notice: "Categories were successfully imported."
  end

  # Displays a paginated list of categories.
  def index
    @categories = Category.page(params[:page])
    @category = Category.new
  end

  # Initializes a new category.
  def new
    @category = Category.new
  end

  # Creates a new category with the given parameters.
  def create
    @category = Category.new(category_params)
    @category.total ||= 0

    if @category.save
      redirect_to categories_path, notice: "Category was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Deletes the specified category.
  def destroy
    @category.destroy
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
end