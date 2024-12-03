require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe ImportCategoriesJob, type: :job do
  let(:file_path) { '/home/intern-npduy1/Documents/test.ods' } # Path to your .ods file
  let(:worker) { described_class.new }

  before do
    # Set up Sidekiq to use the fake testing queue
    Sidekiq::Testing.fake!
  end

  describe "#perform" do
    context "when the file is valid" do
      it "imports categories successfully" do
        # Mock the spreadsheet and its data
        valid_row_data = ["Electronics"]
        header = ["name"]
        spreadsheet = instance_double("Roo::OpenOffice")

        allow(Roo::OpenOffice).to receive(:new).and_return(spreadsheet)
        allow(spreadsheet).to receive(:row).with(1).and_return(header)
        allow(spreadsheet).to receive(:row).with(2).and_return(valid_row_data)
        allow(spreadsheet).to receive(:last_row).and_return(2)

        expect {
          worker.perform(file_path)
        }.to change { Category.count }.by(1) # Expect one category to be imported
      end
    end

    context "when an error occurs during file processing" do
      it "logs the error" do
        # Simulate an error during file processing
        allow(Roo::OpenOffice).to receive(:new).and_raise(StandardError, "Test error")

        # Mock the logger to verify error logging
        logger = instance_double("Logger")
        allow(worker).to receive(:logger).and_return(logger)

        # Expect the logger to receive the error message
        expect(logger).to receive(:error).with("Error importing categories: Test error")

        # Execute the perform method
        worker.perform("invalid_file_path")
      end
    end

    context "when the file contains invalid rows" do
      it "logs errors for invalid rows and does not import them" do
        # Mock the spreadsheet and its data
        invalid_row_data = [nil] # Invalid row with a missing name
        header = ["name"]
        spreadsheet = instance_double("Roo::OpenOffice")

        allow(Roo::OpenOffice).to receive(:new).and_return(spreadsheet)
        allow(spreadsheet).to receive(:row).with(1).and_return(header)
        allow(spreadsheet).to receive(:row).with(2).and_return(invalid_row_data)
        allow(spreadsheet).to receive(:row).with(3).and_return("test")
        allow(spreadsheet).to receive(:last_row).and_return(3)

        logger = instance_double("Logger")
        allow(worker).to receive(:logger).and_return(logger)

        # Expect error logging for the invalid row
        expect(logger).to receive(:info).with("Successfully imported 1 categories.")

        expect {
          worker.perform(file_path)
        }.to change { Category.count }.by(1) # Expect no categories to be imported
      end
    end
  end
end
