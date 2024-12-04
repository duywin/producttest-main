# spec/rails_helper.rb
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"

# Automatically require files in spec/support and its subdirectories
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |file| require file }

# Check for pending migrations and apply them before tests are run
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
  # Set fixture path for ActiveRecord
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # Run each example within a transaction (ActiveRecord)
  config.use_transactional_fixtures = true

  # Automatically infer spec types based on file location
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails and gem backtraces
  config.filter_rails_from_backtrace!
  # config.filter_gems_from_backtrace("gem name") # Uncomment to filter specific gems
end
