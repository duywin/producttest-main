require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe ImportAccountsJob, type: :job do
  let(:file_path) { '/home/intern-npduy1/Documents/user.ods' } # Path to your .ods file
  let(:worker) { described_class.new }

  before do
    # To ensure the job uses the fake test queue (i.e., doesn't run in the real queue)
    Sidekiq::Testing.fake!
  end

  describe "#perform" do
    context "when the file is valid" do
      it "imports accounts successfully" do
        expect {
          worker.perform(file_path)
        }.to change { Account.count }.by(1)  # Expecting one account to be added
      end
    end

    context "when the file contains both valid and invalid rows" do
      it "imports valid accounts, logs errors for invalid rows, and logs the success message" do
        # Mock the spreadsheet and its data
        valid_row_data = ["valid_user", "user@example.com", "Password123!", "1"]
        invalid_row_data = ["invalid_user", "invalidemail.com", "password", "0"] # Invalid email and weak password
        header = ["username", "email", "password", "isadmin"]
        spreadsheet = instance_double("Roo::OpenOffice")

        allow(Roo::OpenOffice).to receive(:new).and_return(spreadsheet)
        allow(spreadsheet).to receive(:row).with(1).and_return(header)
        allow(spreadsheet).to receive(:row).with(2).and_return(valid_row_data)
        allow(spreadsheet).to receive(:row).with(3).and_return(invalid_row_data)
        allow(spreadsheet).to receive(:last_row).and_return(3)

        logger = instance_double("Logger")
        allow(worker).to receive(:logger).and_return(logger)

        # Expect error logging for the invalid row
        expected_error_message = "Invalid account data at row 3: Email is invalid, Password must include at least one uppercase letter, Password must include at least one number, Password must include at least one symbol"

        expect(logger).to receive(:error).with(expected_error_message)

        # Expect info logging for the success message
        expect(logger).to receive(:info).with("Accounts were successfully imported: 1 accounts")

        # Expect only the valid account to be imported
        expect {
          worker.perform(file_path)
        }.to change { Account.count }.by(1)
      end
    end


    context "when an error occurs during file processing" do
      it "logs the error" do
        # Simulate an error in file processing
        allow(Roo::OpenOffice).to receive(:new).and_raise(StandardError, "Test error")

        # Set up a logger spy
        logger = instance_double("Logger")
        allow(worker).to receive(:logger).and_return(logger)

        # Expect the logger to receive the error message
        expect(logger).to receive(:error).with("Error reading file: Test error")

        # Execute the method
        worker.perform("invalid_file_path")
      end
    end
  end

end
