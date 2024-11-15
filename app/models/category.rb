class Category < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  def self.ransackable_attributes(auth_object = nil)
    ["name"]
  end
  def self.category_totals
    group(:name).sum(:total)
  end
end
