# app/lib/month_logger.rb
require 'logger'
require 'fileutils'

class MonthLogger
  LOG_DIR = Rails.root.join('log', 'monthly_logs')

  def initialize(model_class)
    @model_class = model_class
    FileUtils.mkdir_p(LOG_DIR) unless File.directory?(LOG_DIR)
    @logger = Logger.new(log_file_path, 'monthly')
  end

  def log_file_path
    month = Time.now.strftime("%Y-%m")
    LOG_DIR.join("#{@model_class.name}_#{month}.log")
  end

  def info(message, user_id = nil)
    @logger.info(format_message(message, user_id))
  end

  def warn(message, user_id = nil)
    @logger.warn(format_message(message, user_id))
  end

  private

  def format_message(message, user_id)
    user_info = user_id ? "User ID: #{user_id} - " : ""
    "#{user_info}#{message}"
  end
end
