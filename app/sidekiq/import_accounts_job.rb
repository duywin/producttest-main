# app/jobs/import_accounts_job.rb
class ImportAccountsJob < SidekiqWorker
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
        is_admin = row[header.index("isadmin")].to_i == 1

        # Build an account for validation
        account = Account.new(username: username, email: email, password: password, is_admin: is_admin)
        if account.valid?
          accounts << account
        else
          logger.error("Invalid account data at row #{i}: #{account.errors.full_messages.join(', ')}")
        end
      end
    rescue => e
      logger.error("Error reading file: #{e.message}")
      return
    end

    if accounts.present?
      Account.import accounts
      logger.info("Accounts were successfully imported: #{accounts.count} accounts")
    end
  end
end
