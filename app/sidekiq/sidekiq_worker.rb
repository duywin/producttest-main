class SidekiqWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5 # Default retry options

  # Initialize the logger for this worker
  def logger
    @logger ||= MonthLogger.new(SidekiqWorker)  # Pass the class itself, not a string
  end

  # Common method for all jobs to be performed
  def perform(*args)
    logger.info("Job started with arguments: #{args}")
    do_some_work(args)

    logger.info("Job completed successfully.")
  rescue StandardError => e
    logger.warn("Job failed with error: #{e.message}")
    raise e  # Ensure Sidekiq retries the job as per the retry strategy
  end

  private

  # This method should be overridden by subclasses to define specific job logic
  def do_some_work(args)
    raise NotImplementedError, "Subclasses must implement the 'do_some_work' method"
  end
end
