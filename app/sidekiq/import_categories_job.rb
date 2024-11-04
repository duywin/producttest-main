# app/jobs/import_categories_job.rb
class ImportCategoriesJob < ApplicationJob
  queue_as :default

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
      Rails.logger.error "Error importing categories: #{e.message}"
      return
    end

    Category.import(categories)
  ensure
    File.delete(file_path) if File.exist?(file_path)
  end
end
