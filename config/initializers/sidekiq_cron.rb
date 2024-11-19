# config/initializers/sidekiq_cron.rb
require 'sidekiq/cron/job'

# Weekly report export job - runs every Monday at 8:00 AM
Sidekiq::Cron::Job.create(
  name: 'weekly_report_export',  # Job name (for reference)
  cron: '0 8 * * 1',             # Cron expression (Monday at 8:00 AM)
  class: 'WeeklyReportJob',      # The job class to run
  queue: 'default',              # Optional: specify the queue, if necessary
  description: 'Export weekly report every Monday at 8 AM'
)

# Monthly report export job - runs at 8:00 AM on the 1st day of every month
Sidekiq::Cron::Job.create(
  name: 'monthly_report_export', # Job name (for reference)
  cron: '0 8 1 * *',             # Cron expression (1st of every month at 8:00 AM)
  class: 'MonthlyReportJob',     # The job class to run
  queue: 'default',              # Optional: specify the queue, if necessary
  description: 'Export monthly report on the 1st day of every month at 8 AM'
)
