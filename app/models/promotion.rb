class Promotion < ApplicationRecord
  # Associations
  has_many :promote_products, dependent: :destroy

  # Scopes for reports
  scope :weekly_report, -> { where("end_date >= ?", Date.today.end_of_week) }
  scope :monthly_report, -> { where(created_at: Time.current.beginning_of_month..Time.current.end_of_month) }
end
