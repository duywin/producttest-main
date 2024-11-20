class WeeklyReportJob < SidekiqWorker
  def do_some_work(args)
    admin_id = args.present? ? args.first : 8
    admin = Account.find(admin_id)

    # Calculate the week number of the current month
    week_number = week_of_month(Date.today)
    month_name = Date.today.strftime("%B")

    # Generate the weekly report and get the filename
    filename = PromotionReportExporter.export_weekly_report(week_number, month_name)
    file_path = Rails.root.join('tmp', filename)

    unless File.exist?(file_path)
      logger.warn("Failed to locate the generated report: #{filename}")
      return
    end

    # Move the generated file to the downloads directory
    downloads_path = Rails.root.join('public', 'downloads', filename)
    FileUtils.mkdir_p(File.dirname(downloads_path))
    File.rename(file_path, downloads_path)

    logger.info("Weekly Report Exported: #{downloads_path}")

    # Create a notification for the admin with the download link
    Notification.create!(
      admin_id: admin.id,
      message: "Weekly report for Week #{week_number}, #{month_name} #{Time.now.strftime('%Y')} is ready.",
      link: "/downloads/#{filename}"
    )
  end

  # Helper method to calculate the week of the month
  def week_of_month(date)
    (date.day - 1) / 7 + 1
  end
end
