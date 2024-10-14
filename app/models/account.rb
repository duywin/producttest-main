class Account < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true

  after_initialize :set_defaults, if: :new_record?
  validate :password_complexity

  def self.ransackable_attributes(auth_object = nil)
    [ "username", "email", "created_at"]

  end

  private

  def password_complexity
    return if password.blank?

    unless password.match(/(?=.*[A-Z])/).present? # At least one uppercase letter
      errors.add :password, 'must include at least one uppercase letter'
    end

    unless password.match(/(?=.*\d)/).present? # At least one number
      errors.add :password, 'must include at least one number'
    end

    unless password.match(/(?=.*[\W_])/).present? # At least one symbol
      errors.add :password, 'must include at least one symbol'
    end
  end

  def set_defaults
    self.gender ||= "none"
    self.address ||= ""
    self.phonenumber ||= ""
  end

  def generate_and_send_otp
    otp = SecureRandom.hex(4)
    update(otp_code: otp)
    AccountMailer.with(account: self, otp: otp).otp_email.deliver_now
  end
end
