# app/workers/monthly_report_job.rb
class MonthlyReportJob < SidekiqWorker
  # Override the 'do_some_work' method to define the specific logic for monthly report export
  def do_some_work(args)
    filename = PromotionReportExporter.export_monthly_report
    logger.info("Monthly Report Exported: #{filename}")
  end
end
