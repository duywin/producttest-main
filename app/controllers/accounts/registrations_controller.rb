class Accounts::RegistrationsController < Devise::RegistrationsController
  def new
    super
  end

  def create
    build_resource(account_params)
    resource.is_admin = false

    if resource.save
      set_flash_message! :notice, :signed_up
      redirect_to new_account_session_path, notice: "Account created successfully. Please log in."
    else
      clean_up_passwords(resource)
      set_flash_message! :alert, :sign_up_failed
      render :new
    end
  end

  protected

  def account_params
    params.require(:account).permit(:username, :email, :password, :password_confirmation)
  end
end
