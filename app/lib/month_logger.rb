# app/lib/month_logger.rb
require 'log4r'
require 'fileutils'

class MonthLogger
  LOG_DIR = Rails.root.join('log', 'monthly_logs')

  def initialize(model_class)
    @model_class = model_class
    FileUtils.mkdir_p(LOG_DIR) unless File.directory?(LOG_DIR)
    @logger = setup_logger
  end

  def log_file_path
    month = Time.now.strftime("%Y-%m")
    LOG_DIR.join("#{@model_class.name}_#{month}.log").to_s  # Convert Pathname to String
  end

  def info(message, user_id = nil)
    @logger.info(format_message(message, user_id))
  end

  def warn(message, user_id = nil)
    @logger.warn(format_message(message, user_id))
  end

  private

  def setup_logger
    logger = Log4r::Logger.new(@model_class.name)
    logger.outputters = Log4r::Outputter.stdout # Log to STDOUT as well
    logger.outputters << Log4r::FileOutputter.new(
      'monthly_log',
      filename: log_file_path,  # This is now a String
      trunc: false,
      formatter: Log4r::PatternFormatter.new(pattern: "%d [%l] %m")
    )
    logger
  end

  def format_message(message, user_id)
    user_info = user_id ? "User ID: #{user_id} - " : ""
    "#{user_info}#{message}"
  end
end
