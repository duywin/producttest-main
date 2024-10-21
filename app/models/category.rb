class Category < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  paginates_per 5
  def self.ransackable_attributes(auth_object = nil)
    ["name"]
  end
end
