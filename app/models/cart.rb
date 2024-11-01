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

  # Filter and helper methods
  scope :checked_out, -> { where(check_out: true) }
  scope :by_week, ->(week_start) { where(created_at: week_start.beginning_of_day..week_start.end_of_week.end_of_day) }
  scope :by_day, ->(date) { where(created_at: date.beginning_of_day..date.end_of_day) }

  def self.apply_filters(carts, week_param, day_param)
    return carts unless week_param.present?

    week_start = Date.strptime(week_param, '%d %b %Y')
    carts = carts.by_week(week_start)
    carts = carts.by_day(week_start.beginning_of_week + day_of_week_number(day_param)) if day_param.present?
    carts
  end

  def self.fetch_weeks_with_checkouts
    checked_out.pluck(:created_at).map(&:beginning_of_week).uniq.sort.reverse
  end

  def self.search_carts(params)
    search_definition = { query: { bool: { filter: [] } } }
    search_definition[:query][:bool][:filter] << { term: { status: params[:status] } } if params[:status].present?

    if params[:week].present?
      week_start = Date.strptime(params[:week], '%d %b %Y').beginning_of_week
      search_definition[:query][:bool][:filter] << { range: { created_at: { gte: week_start, lte: week_start.end_of_week } } }

      if params[:day].present?
        day_of_week = Date::DAYNAMES.index(params[:day].capitalize)
        search_definition[:query][:bool][:filter] << { script: { script: "doc['created_at'].value.dayOfWeek == #{day_of_week}" } }
      end
    end

    __elasticsearch__.search(search_definition)
  end

  # Returns formatted data for cart
  def formatted_data
    {
      id: id,
      username: account&.username || 'N/A',
      total: ActionController::Base.helpers.number_to_currency(total_price),
      address: address.presence || 'N/A',
      status: status.presence || 'N/A',
      actions: %(
        <div class="d-flex gap-2 justify-content-center">
          <button type="button" onclick="window.location='#{Rails.application.routes.url_helpers.cart_path(self)}'" class="btn btn-outline-primary btn-sm" title="View Details">👁</button>
          <button type="button" onclick="window.location='#{Rails.application.routes.url_helpers.edit_cart_path(self)}'" class="btn btn-primary btn-sm" title="Edit Cart">✎</button>
        </div>
      )
    }
  end
end
