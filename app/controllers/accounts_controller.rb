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
  end

  def render_account_datatable
    query = params[:username_cont].presence
    created_at_filter = params[:created_at_filter]

    @accounts = if query.present?
                  Account.search(query, created_at_filter).records
                else
                  Account.all
                end

    data = @accounts.map do |account|
      {
        id: account.id,
        username: account.username,
        email: account.email,
        status: account.is_admin ? 'Admin' : 'User',
        actions: %(
        <div class="d-flex gap-3 align-items-center">
          <button type="button" onclick="window.location='#{account_path(account)}'" class="btn btn-primary" style="color: white; padding: 10px 20px; border-radius: 5px; border: none; cursor: pointer; background: none; font-size: 20px;" title="View Details">
            <span>👁</span>
          </button>
          <button type="button" onclick="window.location='#{edit_account_path(account)}'" class="btn btn-primary" style="color: blue; padding: 10px 20px; border-radius: 5px; border: none; cursor: pointer; background: none; font-size: 20px;" title="Edit Account">
            <span>✎</span>
          </button>
          <button type="button" data-method="delete" data-confirm="Are you sure?" class="btn btn-danger delete-account-btn" data-account-id="#{account.id}" style="background: none; padding: 10px 20px; border-radius: 5px; border: none; color: red; cursor: pointer; font-size: 20px;" title="Delete Account">
            <span>❌</span>
          </button>
        </div>
      )
      }
    end

    render json: { data: data, status: 200 }
  end

  # Import accounts from an uploaded ODS file
  def import
    file = params[:file]
    if file.nil?
      redirect_to accounts_path, alert: "Please upload an ODS file."
      return
    end

    # Check if the file is of the right type
    unless File.extname(file.path) == '.ods'
      redirect_to accounts_path, alert: "Please upload a valid ODS file."
      return
    end

    # Move the file to a temporary location
    temp_file_path = File.join(Dir.tmpdir, file.original_filename)
    File.open(temp_file_path, 'wb') do |f|
      f.write(file.read)
    end

    ImportAccountsJob.perform_later(temp_file_path)
    month_logger.info("Account import started for file '#{file.original_filename}'", session[:current_account_id])

    redirect_to accounts_path, notice: "Importing accounts. You will be notified once the import is complete."
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
      month_logger.info("Account '#{@account.username}' (ID: #{@account.id}) was created", session[:current_account_id])
      redirect_to @account, notice: "Account was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @account.update(account_params)
      month_logger.info("Account '#{@account.username}' (ID: #{@account.id}) was updated", session[:current_account_id])
      redirect_to @account, notice: "Account was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @account.destroy
    month_logger.warn("Account '#{@account.username}' (ID: #{@account.id}) was destroyed", session[:current_account_id])
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

  # Initializes the monthly logger for this controller.
  def month_logger
    @month_logger ||= MonthLogger.new(Account)
  end
end
