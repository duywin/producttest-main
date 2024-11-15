require 'concurrent'
class AdminhomesController < ApplicationController
  before_action :authenticate_admin

  def index
    @account = Account.find_by(id: session[:current_account_id])
    @category_totals = Category.group(:name).sum(:total)

    @highest_category = @category_totals.max_by { |_category, total| total }
    @top_product = find_top_product

    @monthly_sales_js = monthly_sales_data.to_json
    @monthly_category_sales_js = monthly_category_sales_data.to_json

    @current_month_category_sales = fetch_current_month_category_sales
  end

  # Logout the current admin by clearing the session
  def adminlogout
    month_logger.info("Account logged out (ID: #{session[:current_account_id]})", session[:current_account_id])
    session.delete(:current_account_id) if session[:current_account_id]
    redirect_to new_account_session_path
  end

  def export_report
    # Fetch data from `index`
    index # Ensures the required data is available for the PDF

    # Render the HTML for the charts
    html = render_to_string(
      template: "adminhomes/export_report",
      layout: "layouts/application",
      locals: {
        monthly_sales_js: @monthly_sales_js,
        monthly_category_sales_js: @monthly_category_sales_js,
        current_month_category_sales: @current_month_category_sales,
        highest_category: @highest_category,
        top_product: @top_product,
        category_totals: @category_totals
      }
    )

    # Generate and save PDF with Grover
    pdf = Grover.new(html, format: 'A4').to_pdf
    file_path = Rails.root.join('public', 'downloads', 'admin_report.pdf')
    FileUtils.mkdir_p(File.dirname(file_path))

    # Write the binary PDF data to the file in binary mode
    File.open(file_path, "wb") do |file|
      file.write(pdf)
    end

    # Send the file as an attachment to the user
    send_file file_path, filename: 'admin_report.pdf', type: 'application/pdf', disposition: 'attachment'
  end


  # Render category totals as JSON
  def category_totals
    category_totals = Category.group(:name).sum(:total)
    render json: category_totals.map { |name, total| [name, total] }
  end

  private
  def fetch_current_month_category_sales
    current_month = Date.current.strftime("%Y-%m")
    CartItem.joins(:product)
            .where("DATE_FORMAT(cart_items.created_at, '%Y-%m') = ?", current_month)
            .group("products.product_type")
            .sum(:quantity)
            .map { |category, quantity| { name: category, y: quantity } }
  end


  def monthly_sales_data
    Cart.where.not(deliver_day: nil)
        .group("DATE_FORMAT(deliver_day, '%Y-%m')") # Group by year and month
        .sum(:quantity)
        .transform_keys { |date| Date.strptime(date, "%Y-%m").strftime("%B %Y") }
  end

  def monthly_category_sales_data
    CartItem.joins(:product)
            .group("DATE_FORMAT(cart_items.created_at, '%Y-%m')", "products.product_type")
            .sum(:quantity)
            .each_with_object({}) do |((month, category), quantity), hash|
      formatted_month = Date.strptime(month, "%Y-%m").strftime("%B %Y")
      hash[formatted_month] ||= {}
      hash[formatted_month][category] = quantity
    end
  end

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