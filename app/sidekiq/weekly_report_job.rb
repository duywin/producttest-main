# app/workers/weekly_report_job.rb
class WeeklyReportJob < SidekiqWorker
  # Override the 'do_some_work' method to define the specific logic for weekly report export
  def do_some_work(args)
    filename = PromotionReportExporter.export_weekly_report
    logger.info("Weekly Report Exported: #{filename}")
  end
end
