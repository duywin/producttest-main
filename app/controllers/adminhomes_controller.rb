class AdminhomesController < ApplicationController
  before_action :authenticate_admin

  # Logout the current admin by clearing the session
  def adminlogout
    month_logger.info("Account logged out (ID: #{session[:current_account_id]})", session[:current_account_id])
    session.delete(:current_account_id) if session[:current_account_id]
    redirect_to new_account_session_path
  end

  # Admin dashboard displaying category totals and top product
  def index
    @account = Account.find_by(id: session[:current_account_id])
    @category_totals = Category.group(:name).sum(:total)
    @highest_category = @category_totals.max_by { |_category, total| total }

    # Call the method to find the top product
    @top_product = find_top_product

    # Convert category totals to JSON for use in JavaScript
    @category_totals_js = @category_totals.map { |name, total| [name, total] }.to_json
  end

  # Render category totals as JSON
  def category_totals
    category_totals = Category.group(:name).sum(:total)
    render json: category_totals.map { |name, total| [name, total] }
  end

  private

  # Ensure the current user is an admin
  def authenticate_admin
    if session[:current_account_id].nil?
      redirect_to noindex_path unless request.path == noindex_path # Prevent redirect loop
    end
  end

  # Find the top product based on cart item quantity
  def find_top_product
    CartItem.joins(:product)
            .group("products.id")
            .select("products.name, products.picture, SUM(cart_items.quantity) AS total_quantity")
            .order("total_quantity DESC")
            .limit(1)
            .first
  end

  def month_logger
    @month_logger ||= MonthLogger.new(Account)
  end
end
