class Category < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true

  # Define ransackable attributes for searching
  def self.ransackable_attributes(_auth_object = nil)
    ["name"]
  end

  # Method to calculate total grouped by category name
  def self.category_totals
    group(:name).sum(:total).map do |name, total|
      { name: name, total: total }
    end
  end
end
