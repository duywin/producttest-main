class CategoriesController < ApplicationController
  before_action :set_category, only: [:destroy]
  before_action :authenticate_admin

  def authenticate_admin
    if session[:current_account_id].nil?
      unless request.path == noindex_path # Ensure we aren't redirecting in a loop
        redirect_to noindex_path
      end
    end
  end
  def refreshtotal
    Category.find_each do |category|
      total_count = Product.where(product_type: category.name).count
      category.update(total: total_count)
    end
    redirect_to categories_path, notice: 'Total counts refreshed successfully.'
  end

  def import
    file = params[:file]
    if file.nil?
      redirect_to categories_path, alert: 'Please upload an ODS file.'
      return
    end

    categories = []

    # Read the ODS file
    begin
      spreadsheet = Roo::OpenOffice.new(file.path)

      # Assuming the first row is the header
      header = spreadsheet.row(1)

      # Start from the second row to skip the header
      (2..spreadsheet.last_row).each do |i|
        row = spreadsheet.row(i)
        name = row[header.index('name')]  # Assuming 'name' is the header for category names
        categories << Category.new(name: name, total: 0) if name.present?
      end

    rescue => e
      redirect_to categories_path, alert: "Error reading file: #{e.message}"
      return
    end

    Category.import(categories)
    redirect_to categories_path, notice: 'Categories were successfully imported.'
  end




  # GET /categories
  def index
    @categories = Category.page(params[:page]) # Apply pagination
    @category = Category.new
  end

  # GET /categories/new
  def new
    @category = Category.new
  end

  # POST /categories
  def create
    @category = Category.new(category_params)
    @category.total ||= 0
    if @category.save
      redirect_to categories_path, notice: 'Category was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @category = Category.find(params[:id])
    @category.destroy
    redirect_to categories_path, notice: 'Category was successfully deleted.'
  end

  private
  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:id, :name, :total)
  end
end

