class AccountsController < ApplicationController
  before_action :set_account, only: %i[show edit update destroy]
  before_action :authenticate_admin, only: [:index]

  # Ensures the user is an admin before accessing certain actions.
  def authenticate_admin
    unless session[:current_account_id]
      redirect_to noindex_path unless request.path == noindex_path # Prevent redirect loop.
    end
  end

  # Lists accounts with search and filter options.
  def index; end

  # Renders a datatable with account details.
  def render_account_datatable
    query = params[:username_cont].presence
    created_at_filter = params[:created_at_filter]

    @accounts = query.present? ? Account.search(query, created_at_filter).records : Account.all

    data = @accounts.map do |account|
      {
        id: account.id,
        username: account.username,
        email: account.email,
        status: account.is_admin ? 'Admin' : 'User',
        actions: render_action_buttons(account)
      }
    end

    render json: { data: data, status: 200 }
  end

  # Imports accounts from an uploaded ODS file.
  def import
    file = params[:file]
    if file.blank?
      redirect_to accounts_path, alert: "Please upload an ODS file."
      return
    end

    unless valid_file?(file)
      redirect_to accounts_path, alert: "Please upload a valid ODS file."
      return
    end

    temp_file_path = save_temp_file(file)
    ImportAccountsJob.perform_async(temp_file_path)
    log_action("Account import started for file '#{file.original_filename}'")

    redirect_to accounts_path, notice: "Importing accounts. You will be notified once the import is complete."
  end

  def show; end

  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params_with_defaults)

    if @account.save
      log_action("Account '#{@account.username}' (ID: #{@account.id}) was created")
      redirect_to @account, notice: "Account was successfully created."
    else
      render :new
    end
  end

  def edit; end

  def update
    if @account.update(account_params)
      log_action("Account '#{@account.username}' (ID: #{@account.id}) was updated")
      redirect_to @account, notice: "Account was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @account.destroy
    log_action("Account '#{@account.username}' (ID: #{@account.id}) was destroyed", :warn)
    redirect_to accounts_url, notice: "Account was successfully destroyed."
  end

  private

  # Renders action buttons for accounts in the datatable.
  def render_action_buttons(account)
    <<~HTML.squish
      <div class="d-flex gap-3 align-items-center">
        <button onclick="window.location='#{account_path(account)}'" class="btn btn-primary" title="View Details">
          👁
        </button>
        <button onclick="window.location='#{edit_account_path(account)}'" class="btn btn-primary" title="Edit Account">
          ✎
        </button>
        <button data-method="delete" data-confirm="Are you sure?" class="btn btn-danger delete-account-btn" data-account-id="#{account.id}" title="Delete Account">
          ❌
        </button>
      </div>
    HTML
  end

  # Validates the uploaded file.
  def valid_file?(file)
    File.extname(file.path) == '.ods'
  end

  # Saves the uploaded file to a temporary location.
  def save_temp_file(file)
    temp_file_path = File.join(Dir.tmpdir, file.original_filename)
    File.open(temp_file_path, 'wb') { |f| f.write(file.read) }
    temp_file_path
  end

  # Sets default attributes for account creation.
  def account_params_with_defaults
    account_params.merge(gender: account_params[:gender].presence || "none", address: account_params[:address].presence || "", phonenumber: account_params[:phonenumber].presence || "")
  end

  # Logs actions with an optional severity level.
  def log_action(message, severity = :info)
    month_logger.public_send(severity, message, session[:current_account_id])
  end

  # Finds the account based on the ID from the params.
  def set_account
    @account = Account.find(params[:id])
  end

  # Permits only allowed parameters for account creation or update.
  def account_params
    params.require(:account).permit(:username, :password, :is_admin, :email, :phonenumber, :address, :gender)
  end

  # Initializes the monthly logger for this controller.
  def month_logger
    @month_logger ||= MonthLogger.new(Account)
  end
end
