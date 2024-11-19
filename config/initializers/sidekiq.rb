require 'sidekiq'
require 'sidekiq-cron'

# Configure Sidekiq server and client with Redis URL
Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/0' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://localhost:6379/0' }
end

# Load Sidekiq Cron jobs from schedule.yml
schedule_file = Rails.root.join('config', 'schedule.yml')
if File.exist?(schedule_file)
  Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file))
else
  Rails.logger.error("Cron job schedule file not found: #{schedule_file}")
end
