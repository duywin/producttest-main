class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items
  belongs_to :account
  paginates_per 10

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
  } do
    mappings dynamic: false do
      indexes :id, type: :integer
      indexes :account_id, type: :integer
      indexes :status, type: :keyword, normalizer: "lowercase_normalizer"
      indexes :deliver_day, type: :date
      indexes :created_at, type: :date
    end
  end

  after_create :index_to_elasticsearch
  after_update :update_in_elasticsearch

  def index_to_elasticsearch
    __elasticsearch__.index_document
  end

  def update_in_elasticsearch
    __elasticsearch__.update_document
  end

  # Elasticsearch search method for filtering and sorting
  def self.search_carts(params)
    search_definition = {
      query: {
        bool: {
          must: [
            { match: { check_out: true } }
          ],
          filter: []
        }
      },
      sort: [
        { created_at: { order: params[:sort_order] || 'desc' } }
      ]
    }

    # Filter by status if provided
    search_definition[:query][:bool][:filter] << { term: { status: params[:status] } } if params[:status].present?

    # Filter by week (deliver_day range) if provided
    if params[:week].present?
      start_of_week = Date.parse(params[:week]).beginning_of_week
      end_of_week = Date.parse(params[:week]).end_of_week
      search_definition[:query][:bool][:filter] << {
        range: { deliver_day: { gte: start_of_week, lte: end_of_week } }
      }
    end

    # Filter by day of the week if provided
    if params[:day].present?
      search_definition[:query][:bool][:filter] << {
        script: {
          script: "doc['created_at'].date.dayOfWeek == #{day_of_week_number(params[:day])}"
        }
      }
    end

    __elasticsearch__.search(search_definition)
  end

  # Helper method to map day names to Elasticsearch day numbers
  def self.day_of_week_number(day)
    case day.downcase
    when 'monday' then 1
    when 'tuesday' then 2
    when 'wednesday' then 3
    when 'thursday' then 4
    when 'friday' then 5
    when 'saturday' then 6
    when 'sunday' then 7
    else nil
    end
  end

  def total_price
    cart_items.includes(:product).sum("cart_items.quantity * products.prices")
  end
end
