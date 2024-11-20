# app/workers/notify_report_export_worker.rb
class NotifyReportExportWorker < SidekiqWorker
  private

  def do_some_work(args)
    if args.present?
      admin_id = args.first
    else
      admin_id = 8
    end
    admin = Account.find(admin_id)

    @account = Account.find(admin_id)
    @category_totals = Category.category_totals
    @highest_category = @category_totals.max_by { |_category, total| total }
    @top_product = Product.find_top_product
    @monthly_sales_js = Cart.monthly_sales_data.to_json
    @monthly_category_sales_js = Cart.monthly_category_sales_data.to_json
    @current_month_category_sales = CartItem.current_month_category_sales

    # Generate HTML with locals
    html = ApplicationController.render(
      template: "adminhomes/export_report",
      layout: "layouts/application",
      locals:{
        account: @account,
        monthly_sales_js: @monthly_sales_js,
        monthly_category_sales_js: @monthly_category_sales_js,
        current_month_category_sales: @current_month_category_sales,
        highest_category: @highest_category,
        top_product: @top_product,
        category_totals: @category_totals
      }
    )

    # Generate the PDF file
    file_name = "admin_report_#{Time.now.strftime('%Y%m%d')}.pdf"
    pdf = Grover.new(html, format: 'A4').to_pdf
    file_path = Rails.root.join('public', 'downloads', file_name)
    FileUtils.mkdir_p(File.dirname(file_path))
    File.open(file_path, 'wb') { |file| file.write(pdf) }

    # Create notification with the file download link
    Notification.create!(
      admin_id: admin.id,
      message: "Admin daily report for #{Time.now.strftime('%Y-%m-%d')} is ready.",
      link: "/downloads/#{file_name}"
    )
  end

end
