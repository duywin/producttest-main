class Product < ApplicationRecord
  validates :name, presence: true
  validates :prices, presence: true, numericality: { greater_than: 0.00 }
  mount_uploader :picture_file, PictureUploader # mount uploader for file
  paginates_per 10

  has_many :merchandises

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  # Elasticsearch settings for index normalization
  settings index: {
    analysis: {
      normalizer: {
        lowercase_normalizer: {
          type: "custom",
          filter: ["lowercase"]
        }
      }
    }
  }

  # Elasticsearch mappings
  mappings dynamic: false do
    indexes :id, type: :integer
    indexes :name, type: "keyword", normalizer: "lowercase_normalizer"
    indexes :product_type, type: :text
    indexes :prices, type: :float
  end

  # Elasticsearch callbacks
  after_create :index_to_elasticsearch
  after_update :update_in_elasticsearch

  # Method to index document in Elasticsearch after creation
  def index_to_elasticsearch
    __elasticsearch__.index_document
  end

  # Method to update document in Elasticsearch after update
  def update_in_elasticsearch
    __elasticsearch__.update_document
  end

  # Method to get the current price of a product, applying merchandise discount if active
  def current_price
    merchandise = merchandises.where("promotion_end >= ?", Date.today).first
    if merchandise
      prices * (1 - merchandise.cut_off_value / 100)
    else
      prices # Regular price
    end
  end

  # Method to check price status (normal or anomaly)
  def price_status
    merchandise = merchandises.where("promotion_end >= ?", Date.today).first
    merchandise ? "anomaly" : "normal"
  end

  # Define ransackable attributes for searching
  def self.ransackable_attributes(auth_object = nil)
    ["name", "prices", "product_type"]
  end

  # Method to search products using Elasticsearch with query and optional filters
  def self.search(query, filters = {})
    __elasticsearch__.search(
      {
        query: {
          bool: {
            must: [
              {
                wildcard: {
                  name: {
                    value: "*#{query}*", # SQL-like `LIKE %query%` behavior for name
                    boost: 1.0,
                    rewrite: "constant_score"
                  }
                }
              }
            ],
            filter: filters.presence || [] # Apply filters if provided
          }
        }
      }
    )
  end
end
