class MonthlyReportJob < SidekiqWorker
  # Override the 'do_some_work' method to define the specific logic for monthly report export
  def do_some_work(args)
    admin_id = args.present? ? args.first : 8
    admin = Account.find(admin_id)

    # Get the current month and year
    month_name = Date.today.strftime("%B")  # Full month name, e.g., "November"
    year = Date.today.year  # Current year, e.g., 2024

    # Generate the monthly report and get the filename
    filename = PromotionReportExporter.export_monthly_report
    file_path = Rails.root.join('tmp', filename)

    unless File.exist?(file_path)
      logger.warn("Failed to locate the generated report: #{filename}")
      return
    end

    # Move the generated file to the downloads directory
    downloads_path = Rails.root.join('public', 'downloads', filename)
    FileUtils.mkdir_p(File.dirname(downloads_path))
    File.rename(file_path, downloads_path)

    logger.info("Monthly Report Exported: #{downloads_path}")

    # Create a notification for the admin with the download link
    Notification.create!(
      admin_id: admin.id,
      message: "Monthly report for #{month_name} #{year} is ready.",
      link: "/downloads/#{filename}"
    )
  end
end
