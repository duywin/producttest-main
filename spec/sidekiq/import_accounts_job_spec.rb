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

    context "when the file has invalid rows" do
      it "does not import invalid accounts and logs the error" do

        # Prepare a mock row to simulate invalid data (missing username, email, or password)
        invalid_row_data = ["", "invalid_email@", nil, "0"]  # Invalid row: empty username, invalid email, nil password

        # Mock the file reading part and simulate the row processing with invalid data
        spreadsheet = instance_double("Roo::OpenOffice")
        allow(spreadsheet).to receive(:row).and_return(invalid_row_data)

        # Mock the logger to test error handling
        logger = instance_double("Logger")
        allow(worker).to receive(:logger).and_return(logger)
        expect(logger).to receive(:error).with(/Invalid account data at row/)

        # Simulate the job's perform method
        worker.perform(file_path)
      end
    end

    context "when an error occurs during file processing" do
      it "logs the error" do
        allow(worker).to receive(:perform).and_raise(StandardError, "Test error")

        # Set up a logger spy
        logger = instance_double("Logger")
        allow(worker).to receive(:logger).and_return(logger)
        expect(logger).to receive(:error).with("Error reading file: Test error")

        worker.perform(file_path)
      end
    end
  end

  describe "bulk account import" do
    it "performs bulk import with valid accounts" do
      # You can test the import functionality here
      accounts = [
        build(:account, username: 'user45', email: 'user45@gmail.com', password: 'Admin@12')
      ]

      allow(Account).to receive(:import).with(accounts)

      expect { worker.perform(file_path) }.to change { Account.count }.by(1)
      expect(Account).to have_received(:import).with(accounts)
    end
  end
end
