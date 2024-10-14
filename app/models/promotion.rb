class Promotion < ApplicationRecord
  has_many :promote_products, dependent: :destroy
  # Method to get promotions ending after the current week
  def self.weekly_report
    end_of_week = Date.today.end_of_week
    where('end_date >= ?', end_of_week)
  end

  # Method to get promotions created within the current month
  def self.monthly_report
    where(created_at: Time.current.beginning_of_month..Time.current.end_of_month)
  end
end
