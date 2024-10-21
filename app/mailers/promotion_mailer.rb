class PromotionMailer < ApplicationMailer
  default from: "ad@example.com" # Set your sender email

  def monthly_report
    promotions = Promotion.monthly_report
    month_name = Date.today.strftime("%B")
    filename = "Monthly_Promotion_Report_#{month_name}.xlsx"

    PromotionReportExporter.generate_xlsx(promotions, filename)

    attachments["#{filename}.xlsx"] = File.read("#{filename}.xlsx")

    mail(to: "ad@example.com", subject: "Monthly Promotions Report for #{month_name}")
  end
end
