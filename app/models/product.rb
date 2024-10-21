class Product < ApplicationRecord
  validates :name, presence: true
  validates :prices, presence: true, numericality: { greater_than: 0.00 }
  paginates_per 10
  has_many :merchandises

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks


  settings index: {
    analysis: {
      normalizer: {
        lowercase_normalizer: {
          type: 'custom',
          filter: ['lowercase']
        }
      }
    }
  }

  mappings dynamic: false do
    indexes :id, type: :integer
    indexes :name, type: 'keyword', normalizer: 'lowercase_normalizer'
    indexes :product_type, type: :text
    indexes :prices, type: :float
  end

  after_create :index_to_elasticsearch
  after_update :update_in_elasticsearch


  def index_to_elasticsearch
    __elasticsearch__.index_document
  end

  def update_in_elasticsearch
    __elasticsearch__.update_document
  end

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


  def self.search(query, filters = {})
    __elasticsearch__.search(
      {
        query: {
          bool: {
            must: [
              {
                wildcard: {
                  name: {
                    value: "*#{query}*",  # SQL-like `LIKE %query%` behavior for name
                    boost: 1.0,
                    rewrite: 'constant_score'
                  }
                }
              },
            ],
            filter: filters.presence || []  # Apply filters if provided
          }
        }
      }
    )
  end
end
