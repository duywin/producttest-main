require 'rails_helper'

RSpec.describe MonthlyReportJob, type: :job do
  let(:admin) { create(:account) }  # Assuming you are using FactoryBot to create a mock admin user
  let(:filename) { 'report_2024_November.csv' }
  let(:file_path) { Rails.root.join('tmp', filename) }
  let(:downloads_path) { Rails.root.join('public', 'downloads', filename) }

  before do
    # Mock PromotionReportExporter to return a fixed filename
    allow(PromotionReportExporter).to receive(:export_monthly_report).and_return(filename)

    # Ensure file exists (simulating a file already created)
    allow(File).to receive(:exist?).with(file_path).and_return(true)

    # Mock Notification creation
    allow(Notification).to receive(:create!)

    # Mock FileUtils.mkdir_p and File.rename to not actually modify the file system
    allow(FileUtils).to receive(:mkdir_p)
    allow(File).to receive(:rename)
  end

  it "processes the monthly report export and creates a notification" do
    # Perform the job using the correct method signature
    expect {
      described_class.new.perform([admin.id])  # Using perform as intended for Sidekiq jobs
    }.to change(Notification, :count).by(1)  # Check that a notification was created

    # Verify the file was moved to the downloads directory
    expect(FileUtils).to have_received(:mkdir_p).with(File.dirname(downloads_path))
    # Verify that the notification was created with correct data
    expect(Notification).to have_received(:create!).with(
      admin_id: admin.id,
      message: "Monthly report for November 2024 is ready.",
      link: "/downloads/#{filename}"
    )
  end

end
