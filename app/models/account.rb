require "elasticsearch/model"
class Account < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable

  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true

  after_initialize :set_defaults, if: :new_record?
  validate :password_complexity

  settings do
    mappings dynamic: false do
      indexes :username, type: "text", analyzer: "standard"
      indexes :email, type: "keyword"
      indexes :created_at, type: "date"
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

    # Apply created_at filter if provided
    case created_at_filter
    when "this_week"
      search_definition[:query][:bool][:filter] << { range: { created_at: { gte: Time.current.beginning_of_week } } }
    when "this_month"
      search_definition[:query][:bool][:filter] << { range: { created_at: { gte: Time.current.beginning_of_month } } }
    when "last_month"
      search_definition[:query][:bool][:filter] << { range: { created_at: { gte: Time.current.last_month.beginning_of_month, lte: Time.current.last_month.end_of_month } } }
    when "last_year"
      search_definition[:query][:bool][:filter] << { range: { created_at: { gte: Time.current.last_year.beginning_of_year, lte: Time.current.last_year.end_of_year } } }
    end

    __elasticsearch__.search(search_definition)
  end



  private

  def password_complexity
    return if password.blank?

    unless password.match(/(?=.*[A-Z])/).present? # At least one uppercase letter
      errors.add :password, "must include at least one uppercase letter"
    end

    unless password.match(/(?=.*\d)/).present? # At least one number
      errors.add :password, "must include at least one number"
    end

    unless password.match(/(?=.*[\W_])/).present? # At least one symbol
      errors.add :password, "must include at least one symbol"
    end
  end

  def set_defaults
    self.gender ||= "none"
    self.address ||= ""
    self.phonenumber ||= ""
  end

  def generate_and_send_otp
    otp = SecureRandom.hex(4)
    update(otp_code: otp)
    AccountMailer.with(account: self, otp: otp).otp_email.deliver_now
  end
end
