# config/initializers/log4r.rb
require 'log4r'

# Set the default logging level for the root logger
Log4r::Logger.root.level = Log4r::INFO

# Create a logger for general logs
logfile = Log4r::Logger.new('logfile')
logfile.level = Log4r::DEBUG
logfile.outputters = [
  Log4r::FileOutputter.new(
    'logfile',
    filename: Rails.root.join('log', 'development.log').to_s, # Convert Pathname to String
    formatter: Log4r::PatternFormatter.new(pattern: "%d [%l] %m")
  )
]

# Create a logger for error logs
errorlog = Log4r::Logger.new('errorlog')
errorlog.level = Log4r::ERROR
errorlog.outputters = [
  Log4r::FileOutputter.new(
    'errorlog',
    filename: Rails.root.join('log', 'error.log').to_s, # Convert Pathname to String
    formatter: Log4r::PatternFormatter.new(pattern: "%d [%l] %m")
  )
]
