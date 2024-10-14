class AccountsController < ApplicationController
  before_action :set_account, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_admin, only: [:index]

  def authenticate_admin
    if session[:current_account_id].nil?
      unless request.path == noindex_path # Ensure we aren't redirecting in a loop
        redirect_to noindex_path
      end
    end
  end

  def index
    @q = Account.ransack(params[:q]) # Initialize Ransack
    @accounts = @q.result(distinct: true).page(params[:page]) # Apply pagination
    # Add custom date range filtering
    case params[:created_at_filter]
    when 'this_week'
      @q.created_at_gteq = Time.current.beginning_of_week
    when 'this_month'
      @q.created_at_gteq = Time.current.beginning_of_month
    when 'last_month'
      @q.created_at_gteq = Time.current.last_month.beginning_of_month
      @q.created_at_lteq = Time.current.last_month.end_of_month
    when 'last_year'
      @q.created_at_gteq = Time.current.last_year.beginning_of_year
      @q.created_at_lteq = Time.current.last_year.end_of_year
    end
    @accounts = @q.result(distinct: true).page(params[:page]) # Apply pagination
  end


  def import
      file = params[:file]

      if file.nil?
        redirect_to accounts_path, alert: 'Please upload an ODS file.'
        return
      end

      accounts = []

      # Read the ODS file
      begin
        spreadsheet = Roo::OpenOffice.new(file.path)

        # Assuming the first row is the header
        header = spreadsheet.row(1)

        # Start from the second row to skip the header
        (2..spreadsheet.last_row).each do |i|
          row = spreadsheet.row(i)
          username = row[header.index('username')]
          email = row[header.index('email')]
          password = row[header.index('password')]
          is_admin = row[header.index('isadmin')] == 1 # 1 is true, 0 is false

          # Only add valid accounts
          if username.present? && email.present? && password.present?
            account = Account.new(
              username: username,
              email: email,
              password: password,
              is_admin: is_admin
            )
            accounts << account
          end
        end

      rescue => e
        redirect_to accounts_path, alert: "Error reading file: #{e.message}"
        return
      end
      if accounts.all?(&:valid?)
        accounts.each(&:save)
        redirect_to accounts_path, notice: 'Accounts were successfully imported.'
      else
        error_messages = accounts.reject(&:valid?).map { |acc| acc.errors.full_messages.join(', ') }.join('; ')
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
    # Set default values for the fields not provided
    @account.gender ||= "none"
    @account.address ||= ""
    @account.phonenumber ||= ""

    if @account.save
      redirect_to @account, notice: 'Account was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @account.update(account_params)
      redirect_to @account, notice: 'Account was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @account.destroy
    redirect_to accounts_url, notice: 'Account was successfully destroyed.'
  end

  private
  def set_account
    @account = Account.find(params[:id])
  end

  def account_params
    params.require(:account).permit(:username, :password, :is_admin, :email, :phonenumber, :address, :gender)
  end
end
