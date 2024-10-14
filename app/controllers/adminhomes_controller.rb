class AdminhomesController < ApplicationController
  before_action :authenticate_admin

  def adminlogout
    session.delete(:current_account_id) if session[:current_account_id]
    redirect_to new_account_session_path
  end

  def index
    @account = Account.find_by(id: session[:current_account_id])
    @category_totals = Category.group(:name).sum(:total)
    @highest_category = @category_totals.max_by { |_category, total| total }

    # Call the new method to find the top product
    @top_product = find_top_product

    # Convert the data to a format suitable for JavaScript
    @category_totals_js = @category_totals.map { |name, total| [name, total] }.to_json
  end

  def category_totals
    category_totals = Category.group(:name).sum(:total)
    render json: category_totals.map { |name, total| [name, total] }
  end

  private

  def authenticate_admin
    if session[:current_account_id].nil?
      unless request.path == noindex_path # Ensure we aren't redirecting in a loop
        redirect_to noindex_path
      end
    end
  end

  # Find the top product sold
  def find_top_product
    CartItem.joins(:product)
            .group('products.id')
            .select('products.name, products.picture, SUM(cart_items.quantity) AS total_quantity')
            .order('total_quantity DESC')
            .limit(1)
            .first
  end
end
