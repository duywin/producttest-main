class AdminhomesController < ApplicationController
  before_action :authenticate_admin

  def index
    load_dashboard_data
    @notifications = Notification.where(admin_id: session[:current_account_id]).order(created_at: :desc).limit(10)
  end

  # Logout the current admin
  def adminlogout
    log_logout
    session.delete(:current_account_id)
    redirect_to new_account_session_path
  end

  # Export the report and trigger asynchronous PDF generation
  def export_report
    promises = build_export_promises
    Concurrent::Promise.zip(*promises).value!
    # Generate the report HTML
    html = render_to_string(
      template: "adminhomes/export_report",
      layout: "layouts/application",
      locals: report_locals
    )
    file_path = generate_pdf(html)
    send_file file_path, filename: 'admin_report.pdf', type: 'application/pdf', disposition: 'attachment'
  end

  # Render category totals as JSON
  def category_totals
    render json: Category.category_totals.to_a
  end

  def notify_report_export
    # Ensure the account ID is passed correctly as an array
    NotifyReportExportWorker.perform_async(session [:current_account_id])  # Pass the admin's ID as an array
    flash[:notice] = 'Report generation initiated. You will be notified when the report is ready.'
    redirect_to adminhomes_path
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
    redirect_to noindex_path if session[:current_account_id].nil? && request.path != noindex_path
  end

  # Log the admin logout event
  def log_logout
    month_logger.info("Account logged out (ID: #{session[:current_account_id]})", session[:current_account_id])
  end

  # Build export report promises
  def build_export_promises
    [
      Concurrent::Promise.execute { @account = Account.find_by(id: session[:current_account_id]) },
      Concurrent::Promise.execute { @category_totals = Category.category_totals },
      Concurrent::Promise.execute do
        @category_totals = Category.category_totals
        @highest_category = @category_totals.max_by { |_category, total| total }
      end,
      Concurrent::Promise.execute { @top_product = Product.find_top_product },
      Concurrent::Promise.execute { @monthly_sales_js = Cart.monthly_sales_data.to_json },
      Concurrent::Promise.execute { @monthly_category_sales_js = Cart.monthly_category_sales_data.to_json },
      Concurrent::Promise.execute { @current_month_category_sales = CartItem.current_month_category_sales }
    ]
  end

  # Define locals for the export report template
  def report_locals
    {
      monthly_sales_js: @monthly_sales_js,
      monthly_category_sales_js: @monthly_category_sales_js,
      current_month_category_sales: @current_month_category_sales,
      highest_category: @highest_category,
      top_product: @top_product,
      category_totals: @category_totals
    }
  end

  # Generate and save the PDF file from the HTML content
  def generate_pdf(html)
    pdf = Grover.new(html, format: 'A4').to_pdf
    file_path = Rails.root.join('public', 'downloads', 'admin_report.pdf')
    FileUtils.mkdir_p(File.dirname(file_path)) # Ensure the directory exists
    File.open(file_path, "wb") { |file| file.write(pdf) }
    file_path
  end

  # Logger instance
  def month_logger
    @month_logger ||= MonthLogger.new(Account)
  end
end
