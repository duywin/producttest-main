# app/jobs/import_accounts_job.rb
class ImportAccountsJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(file_path)
    accounts = []

    begin
      spreadsheet = Roo::OpenOffice.new(file_path)
      header = spreadsheet.row(1) # Assuming the first row is the header

      (2..spreadsheet.last_row).each do |i|
        row = spreadsheet.row(i)
        username = row[header.index("username")]
        email = row[header.index("email")]
        password = row[header.index("password")]
        is_admin = row[header.index("isadmin")].to_i == 1 # Ensure comparison with an integer

        # Only add valid accounts
        if username.present? && email.present? && password.present?
          accounts << Account.new(username: username, email: email, password: password, is_admin: is_admin)
        else
          Rails.logger.error("Invalid account data at row #{i}: username=#{username}, email=#{email}, password=#{password}")
        end
      end
    rescue => e
      Rails.logger.error("Error reading file: #{e.message}")
      return
    end

    # Handle account saving in bulk for better performance
    if accounts.all?(&:valid?)
      Account.import accounts
      Rails.logger.info("Accounts were successfully imported: #{accounts.count} accounts")
    else
      error_messages = accounts.reject(&:valid?).map { |acc| acc.errors.full_messages.join(", ") }.join("; ")
      Rails.logger.error("There were errors with some accounts: #{error_messages}")
    end
  end
end
