class AccountsController < ApplicationController
  before_action :set_account, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_admin, only: [:index]

  # Ensure the user is an admin before allowing access to certain actions
  def authenticate_admin
    if session[:current_account_id].nil?
      redirect_to noindex_path unless request.path == noindex_path # Prevent redirect loop
    end
  end

  # List accounts with search and filter options
  def index
    query = params[:username_cont].presence
    created_at_filter = params[:created_at_filter]

    # Perform search with Elasticsearch, or return all accounts if no query is present
    @accounts = if query.present?
                  Account.search(query, created_at_filter).records.page(params[:page])
                else
                  Account.all.page(params[:page])
                end
  end

  # Import accounts from an uploaded ODS file
  def import
    file = params[:file]
    if file.nil?
      redirect_to accounts_path, alert: "Please upload an ODS file."
      return
    end

    accounts = []
    begin
      spreadsheet = Roo::OpenOffice.new(file.path)
      header = spreadsheet.row(1) # Assuming the first row is the header

      (2..spreadsheet.last_row).each do |i|
        row = spreadsheet.row(i)
        username = row[header.index("username")]
        email = row[header.index("email")]
        password = row[header.index("password")]
        is_admin = row[header.index("isadmin")] == 1

        # Only add valid accounts
        if username.present? && email.present? && password.present?
          accounts << Account.new(username: username, email: email, password: password, is_admin: is_admin)
        end
      end
    rescue => e
      redirect_to accounts_path, alert: "Error reading file: #{e.message}"
      return
    end

    if accounts.all?(&:valid?)
      accounts.each(&:save)
      redirect_to accounts_path, notice: "Accounts were successfully imported."
    else
      error_messages = accounts.reject(&:valid?).map { |acc| acc.errors.full_messages.join(", ") }.join("; ")
      redirect_to accounts_path, alert: "There were errors with some accounts: #{error_messages}"
    end
  end

  def show
  end

  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)
    @account.gender ||= "none"
    @account.address ||= ""
    @account.phonenumber ||= ""

    if @account.save
      redirect_to @account, notice: "Account was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @account.update(account_params)
      redirect_to @account, notice: "Account was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @account.destroy
    redirect_to accounts_url, notice: "Account was successfully destroyed."
  end

  private

  # Set the current account based on the ID from the params
  def set_account
    @account = Account.find(params[:id])
  end

  # Permit only the allowed parameters for account creation or update
  def account_params
    params.require(:account).permit(
      :username,
      :password,
      :is_admin,
      :email,
      :phonenumber,
      :address,
      :gender
    )
  end
end
