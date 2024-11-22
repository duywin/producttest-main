# lib/tasks/fb_models_generation.rake
namespace :factory_bot do
  desc "Generate factories for all models"
  task generate_all: :environment do
    Rails.application.eager_load!

    ApplicationRecord.descendants.each do |model|
      begin
        model_name = model.name.underscore
        puts "Generating factory for #{model_name}..."
        system("rails generate factory_bot:model #{model_name}")
      rescue => e
        puts "Error generating factory for #{model.name}: #{e.message}"
      end
    end
  end
end
