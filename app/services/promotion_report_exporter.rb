class PromotionReportExporter
  def self.export_weekly_report
    promotions = Promotion.weekly_report
    week_number = week_of_month(Date.today) # Get the current week number
    month_name = Date.today.strftime("%B")  # Get the current month name
    filename = "Weekly_Promotion_Report_#{month_name}_Week_#{week_number}"
    generate_xlsx(promotions, filename)
    filename
  end

  def self.export_monthly_report
    promotions = Promotion.monthly_report
    month_name = Date.today.strftime("%B")  # Get the current month name
    filename = "Monthly_Promotion_Report_#{month_name}"
    generate_xlsx(promotions, filename)
    filename
  end

  private

  def self.generate_xlsx(promotions, filename)
    p = Axlsx::Package.new
    wb = p.workbook

    wb.add_worksheet(name: "Promotions Report") do |sheet|
      sheet.add_row ["Promote Code", "Promotion Type", "Apply Field", "Value", "End Date", "Min Quantity", "Created At"]

      promotions.each do |promotion|
        sheet.add_row [
                        promotion.promote_code,
                        promotion.promotion_type,
                        promotion.apply_field,
                        promotion.value,
                        promotion.end_date,
                        promotion.min_quantity,
                        promotion.created_at
                      ]
      end
    end

    file_path = Rails.root.join("public", "#{filename}.xlsx") # Save in public folder
    p.serialize(file_path.to_s)
    file_path.to_s
  end


  def self.week_of_month(date)
    (date.day - 1) / 7 + 1
  end
end
