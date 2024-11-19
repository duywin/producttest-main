class Product < ApplicationRecord
  # Validations
  validates :name, presence: true
  validates :prices, presence: true, numericality: { greater_than: 0.00 }

  # File uploader
  mount_uploader :picture_file, PictureUploader

  # Pagination
  paginates_per 10

  # Associations
  has_many :merchandises

  # Elasticsearch integration
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

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

  mappings dynamic: false do
    indexes :id, type: :integer
    indexes :name, type: "keyword", normalizer: "lowercase_normalizer"
    indexes :product_type, type: :text
    indexes :prices, type: :float
  end

  after_create :index_to_elasticsearch
  after_update :update_in_elasticsearch

  # Elasticsearch methods
  def index_to_elasticsearch
    __elasticsearch__.index_document
  end

  def update_in_elasticsearch
    __elasticsearch__.update_document
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
                    value: "*#{query}*",
                    boost: 1.0,
                    rewrite: "constant_score"
                  }
                }
              }
            ],
            filter: filters.presence || []
          }
        }
      }
    )
  end

  # Methods for pricing
  def current_price
    merchandise = merchandises.where("promotion_end >= ?", Date.today).first
    merchandise ? prices * (1 - merchandise.cut_off_value / 100) : prices
  end

  def price_status
    merchandises.where("promotion_end >= ?", Date.today).exists? ? "anomaly" : "normal"
  end

  # Top product finder
  def self.find_top_product
    CartItem.joins(:product)
            .group("products.id")
            .select("products.name, products.picture, SUM(cart_items.quantity) AS total_quantity")
            .order("total_quantity DESC")
            .limit(1)
            .first
  end

  # Ransack integration
  def self.ransackable_attributes(auth_object = nil)
    %w[name prices product_type]
  end
end
