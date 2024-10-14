class Product < ApplicationRecord
  validates :name, presence: true
  validates :prices, presence: true, numericality: { greater_than: 0.00 }
  paginates_per 10
  has_many :merchandises

  def current_price
    merchandise = merchandises.where('promotion_end >= ?', Date.today).first
    if merchandise
      prices * (1 - merchandise.cut_off_value / 100)
    else
      prices # Regular price
    end
  end

  def price_status
    merchandise = merchandises.where('promotion_end >= ?', Date.today).first
    merchandise ? 'anomaly' : 'normal'
  end

  def self.ransackable_attributes(auth_object = nil)
    ["name", "prices", "product_type"]
  end
end
