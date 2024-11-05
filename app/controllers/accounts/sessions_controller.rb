# app/controllers/accounts/sessions_controller.rb
class Accounts::SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params, only: [:create]

  def create
    @account = Account.find_by(username: params[:account][:username])
    if @account && @account.valid_password?(params[:account][:password])
      session[:current_account_id] = @account.id
      session[:welcome_alert_shown] = true

      # Log successful login
      month_logger.info("Account logged in: '#{@account.username}' (ID: #{@account.id})", @account.id)

      if @account.is_admin
        redirect_to adminhomes_path
      else
        redirect_to users_home_path
      end
    else
      flash.now[:alert] = "Invalid username or password"
      render :new
    end
  end

  def destroy
    account_id = session[:current_account_id]
    if account_id
      # Log logout
    end

    sign_out(current_account)
    session.delete(:current_account_id)
    redirect_to new_account_session_path, notice: "Logged out successfully."
  end

  protected

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:username])
  end

  private

  # Initializes the monthly logger for account sessions
  def month_logger
    @month_logger ||= MonthLogger.new(Account)
  end
end
