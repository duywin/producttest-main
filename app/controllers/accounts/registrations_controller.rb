class Accounts::RegistrationsController < Devise::RegistrationsController
  def new
    super
  end

  def create
    build_resource(account_params)
    resource.is_admin = false

    if resource.save
      month_logger.info("New account created: '#{resource.username}' (ID: #{resource.id})", resource.id)
      set_flash_message! :notice, :signed_up
      redirect_to new_account_session_path, notice: "Account created successfully. Please log in."
    else
      clean_up_passwords(resource)
      set_flash_message! :alert, :sign_up_failed
      render :new
    end
  end

  protected
  def month_logger
    @month_logger ||= MonthLogger.new(Account)
  end
  def account_params
    params.require(:account).permit(:username, :email, :password, :password_confirmation)
  end
end
