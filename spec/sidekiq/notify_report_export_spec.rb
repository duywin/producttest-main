require 'rails_helper'

RSpec.describe NotifyReportExportWorker, type: :worker do
  let(:admin) { create(:account, :admin) }

  it "processes the report export and creates a notification" do
    expect {
      NotifyReportExportWorker.new.perform(admin.id)
    }.to change(Notification, :count).by(1)

    notification = Notification.last
    expect(notification.message).to include("Admin daily report for")
    expect(notification.link).to include("/downloads/admin_report_")
  end
end
