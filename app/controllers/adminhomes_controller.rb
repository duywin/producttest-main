class AdminhomesController < ApplicationController
  before_action :authenticate_admin

  def index
    load_dashboard_data
  end

  # Logout the current admin by clearing the session
  def adminlogout
    month_logger.info("Account logged out (ID: #{session[:current_account_id]})", session[:current_account_id])
    session.delete(:current_account_id) if session[:current_account_id]
    redirect_to new_account_session_path
  end

  #Export the report and trigger asynchronous PDF generation
  def export_report
    # Create a list to hold promises
    promises = []

    # Fetch data concurrently using promises
    promises << Concurrent::Promise.execute do
      @account = Account.find_by(id: session[:current_account_id])
    end

    promises << Concurrent::Promise.execute do
      @category_totals = Category.category_totals
      @highest_category = @category_totals.max_by { |_category, total| total }
    end

    promises << Concurrent::Promise.execute do
      @top_product = Product.find_top_product
    end

    promises << Concurrent::Promise.execute do
      @monthly_sales_js = Cart.monthly_sales_data.to_json
    end

    promises << Concurrent::Promise.execute do
      @monthly_category_sales_js = Cart.monthly_category_sales_data.to_json

    end

    promises << Concurrent::Promise.execute do
      @current_month_category_sales = CartItem.current_month_category_sales
       # Sleep for 2 seconds after fetching current month's category sales
    end

    # Wait for all promises to resolve
    Concurrent::Promise.zip(*promises).value!

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

    # Generate PDF from the rendered HTML
    pdf = Grover.new(html, format: 'A4').to_pdf

    # Save the PDF file to a public directory
    file_path = Rails.root.join('public', 'downloads', 'admin_report.pdf')
    FileUtils.mkdir_p(File.dirname(file_path)) # Ensure the directory exists
    File.open(file_path, "wb") { |file| file.write(pdf) } # Write the file in binary mode

    # Send the file as an attachment to the user
    send_file file_path, filename: 'admin_report.pdf', type: 'application/pdf', disposition: 'attachment'
  end



  # Render category totals as JSON
  def category_totals
    category_totals = Category.category_totals
    render json: category_totals.map { |name, total| [name, total] }
  end

  private

  # Load shared dashboard data
  def load_dashboard_data
    @account = Account.find_by(id: session[:current_account_id])

    @category_totals = Category.category_totals
    @highest_category = @category_totals.max_by { |_category, total| total }
    @top_product = Product.find_top_product

    @monthly_sales_js = Cart.monthly_sales_data.to_json
    @monthly_category_sales_js = Cart.monthly_category_sales_data.to_json

    @current_month_category_sales = CartItem.current_month_category_sales
  end

  # Ensure the current user is an admin
  def authenticate_admin
    if session[:current_account_id].nil?
      redirect_to noindex_path unless request.path == noindex_path # Prevent redirect loop
    end
  end

  def month_logger
    @month_logger ||= MonthLogger.new(Account)
  end
end
