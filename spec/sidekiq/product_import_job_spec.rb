# spec/jobs/product_import_job_spec.rb
require 'rails_helper'

RSpec.describe ProductImportJob, type: :job do
  let(:file_path) { Rails.root.join('spec/fixtures/files/products.ods') }
  let(:logger) { instance_double("Logger") }

  before do
    allow_any_instance_of(ProductImportJob).to receive(:logger).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
  end

  context "when the file contains valid products" do
    it "imports products and logs the success message" do
      # Prepare a mock spreadsheet with valid rows
      valid_rows = [
        ["name", "product_type", "prices", "desc", "stock", "picture"], # Header
        ["Product 1", "Type 1", 100.0, "Description 1", 10, "http://example.com/image1.jpg"],
        ["Product 2", "Type 2", 200.0, "Description 2", 20, "http://example.com/image2.jpg"]
      ]

      mock_spreadsheet(valid_rows)

      # Expect logging of processing and success messages
      expect(logger).to receive(:info).with(/Processing row:/).twice
      expect(logger).to receive(:info).with("2 products were successfully imported.")

      # Perform the job and verify the product count change
      expect {
        described_class.new.perform(file_path)
      }.to change { Product.count }.by(2)
    end
  end

  context "when the file contains invalid products" do
    it "logs errors for invalid products" do
      # Prepare a mock spreadsheet with valid and invalid rows
      invalid_rows = [
        ["name", "product_type", "prices", "desc", "stock", "picture"], # Header
        [nil, "Type 1", 100.0, "Description 1", 10, "http://example.com/image1.jpg"], # Missing name
        ["Product 2", nil, nil, nil, nil, nil] # Partially empty
      ]

      mock_spreadsheet(invalid_rows)

      # Expect logging of processing and error messages
      expect(logger).to receive(:info).with(/Processing row:/).twice
      expect(logger).to receive(:error).with(/Invalid product:/).twice

      # Perform the job and verify no valid product is imported
      expect {
        described_class.new.perform(file_path)
      }.not_to change { Product.count }
    end
  end

  def mock_spreadsheet(rows)
    spreadsheet = instance_double("Roo::OpenOffice")
    allow(Roo::OpenOffice).to receive(:new).and_return(spreadsheet)

    allow(spreadsheet).to receive(:row).and_return(*rows)
    allow(spreadsheet).to receive(:last_row).and_return(rows.size)
  end
end
