class AccountMailer < ApplicationMailer
  def otp_email
    @account = params[:account]
    @otp = params[:otp]
    mail(to: @account.email, subject: "Your OTP Code")
  end
end
