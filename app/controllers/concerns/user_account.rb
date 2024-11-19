module UserAccount
  extend ActiveSupport::Concern

  private

  def account_params
    params.require(:account).permit(:name, :email)
  end

  def set_account
    @account = Account.find_by(id: session[:current_account_id])
  end
end
