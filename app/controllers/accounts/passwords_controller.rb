class Accounts::PasswordsController < Devise::PasswordsController
  # Render the 'forgot password' form
  def new
    super
  end

  # Create reset password request
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      flash[:notice] = "You will receive an email with reset password instructions if the email exists in our system."
      redirect_to new_account_session_path
    else
      flash[:alert] = "No account found with this email address."
      render :new
    end
  end

  # Render the reset password form
  def edit
    self.resource = resource_class.new
    super
  end

  # Update the account's password
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)

    if resource.errors.empty?
      flash[:notice] = "Your password has been successfully updated."
      redirect_to new_account_session_path
    else
      flash[:alert] = resource.errors.full_messages.join(', ')
      render :edit
    end
  end

  private

  def resource_params
    params.require(:account).permit(:email, :reset_password_token, :password, :password_confirmation)
  end
end
