# app/jobs/import_categories_job.rb
class ImportCategoriesJob < SidekiqWorker
  sidekiq_options queue: :default

  def perform(file_path)
    categories = []

    begin
      spreadsheet = Roo::OpenOffice.new(file_path)
      header = spreadsheet.row(1)

      (2..spreadsheet.last_row).each do |i|
        row = spreadsheet.row(i)
        name = row[header.index("name")]
        categories << Category.new(name: name, total: 0) if name.present?
      end
    rescue => e
      logger.error "Error importing categories: #{e.message}"
      return
    end

    # Import categories in bulk for better performance
    Category.import(categories)
    logger.info "Successfully imported #{categories.count} categories."
  end
end
