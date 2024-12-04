class Cart < ApplicationRecord
  # Associations
  belongs_to :account
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  # Pagination
  paginates_per 10

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
  } do
    mappings dynamic: false do
      indexes :id, type: :integer
      indexes :account_id, type: :integer
      indexes :status, type: :keyword, normalizer: "lowercase_normalizer"
      indexes :deliver_day, type: :date
      indexes :created_at, type: :date
    end
  end

  # Callbacks
  after_create :index_to_elasticsearch
  after_update :update_in_elasticsearch

  # Elasticsearch indexing and updating
  attr_accessor :function_check_out, :admin_update

  def index_to_elasticsearch
    __elasticsearch__.index_document if function_check_out
  end

  def update_in_elasticsearch
    __elasticsearch__.update_document if admin_update
  end

  # Scopes
  scope :checked_out, -> { where(check_out: true) }
  scope :by_week, ->(week_start) { where(created_at: week_start.beginning_of_week..week_start.end_of_week) }
  scope :by_day, ->(date) { where(created_at: date.beginning_of_day..date.end_of_day) }

  def self.apply_filters(carts, week_param, day_param)
    return carts if week_param.blank? && day_param.blank?

    if week_param.present?
      week_start = Date.strptime(week_param, '%d %b %Y').beginning_of_week
      carts = carts.by_week(week_start)
    end

    if day_param.present? && week_param.present?
      day_of_week = Date::DAYNAMES.index(day_param.capitalize)
      specific_date = week_start + day_of_week
      carts = carts.by_day(specific_date)
    end

    carts
  end


  def self.fetch_weeks_with_checkouts
    checked_out.pluck(:created_at).map(&:beginning_of_week).uniq.sort.reverse
  end

  def self.search_carts(params)
    carts = checked_out
    carts = apply_filters(carts, params[:week], params[:day])
    carts = carts.where(status: params[:status]) if params[:status].present?
    carts
  end


  # Instance Methods

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

  # Sales Data Methods

  def self.monthly_sales_data
    self.where.not(deliver_day: nil)
         .group("DATE_FORMAT(deliver_day, '%Y-%m')")
         .sum(:quantity)
         .transform_keys { |date| Date.strptime(date, "%Y-%m").strftime("%B %Y") }
  end

  def self.monthly_category_sales_data
    CartItem.joins(:product)
            .group("DATE_FORMAT(cart_items.created_at, '%Y-%m')", "products.product_type")
            .sum(:quantity)
            .each_with_object({}) do |((month, category), quantity), hash|
      formatted_month = Date.strptime(month, "%Y-%m").strftime("%B %Y")
      hash[formatted_month] ||= {}
      hash[formatted_month][category] = quantity
    end
  end
end
