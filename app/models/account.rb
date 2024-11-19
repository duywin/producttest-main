require "elasticsearch/model"

class Account < ApplicationRecord
  # Include Elasticsearch modules for indexing and callbacks
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  # Devise modules for authentication
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Validations
  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validate :password_complexity

  # Elasticsearch settings and mappings
  settings do
    mappings dynamic: false do
      indexes :username, type: "text", analyzer: "standard"
      indexes :email, type: "keyword"
      indexes :created_at, type: "date"
    end
  end

  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  after_create :index_to_elasticsearch
  after_update :update_in_elasticsearch

  # Elasticsearch indexing methods
  def index_to_elasticsearch
    __elasticsearch__.index_document
  end

  def update_in_elasticsearch
    __elasticsearch__.update_document
  end

  # Class methods
  def self.search(query, created_at_filter = nil)
    search_definition = {
      query: {
        bool: {
          should: [
            { match: { username: query } },
            { match: { email: query } }
          ],
          filter: []
        }
      }
    }

    # Apply created_at filters
    if created_at_filter
      search_definition[:query][:bool][:filter] << created_at_filter_range(created_at_filter)
    end

    __elasticsearch__.search(search_definition)
  end

  def self.created_at_filter_range(filter)
    case filter
    when "this_week"
      { range: { created_at: { gte: Time.current.beginning_of_week } } }
    when "this_month"
      { range: { created_at: { gte: Time.current.beginning_of_month } } }
    when "last_month"
      { range: { created_at: { gte: Time.current.last_month.beginning_of_month, lte: Time.current.last_month.end_of_month } } }
    when "last_year"
      { range: { created_at: { gte: Time.current.last_year.beginning_of_year, lte: Time.current.last_year.end_of_year } } }
    end
  end

  # Instance methods
  def generate_and_send_otp
    otp = SecureRandom.hex(4)
    update(otp_code: otp)
    AccountMailer.with(account: self, otp: otp).otp_email.deliver_now
  end

  private

  # Callback methods
  def set_defaults
    self.gender ||= "none"
    self.address ||= ""
    self.phonenumber ||= ""
  end

  # Custom validation for password complexity
  def password_complexity
    return if password.blank?

    unless password.match?(/(?=.*[A-Z])/) # At least one uppercase letter
      errors.add :password, "must include at least one uppercase letter"
    end

    unless password.match?(/(?=.*\d)/) # At least one number
      errors.add :password, "must include at least one number"
    end

    unless password.match?(/(?=.*[\W_])/) # At least one symbol
      errors.add :password, "must include at least one symbol"
    end
  end
end
