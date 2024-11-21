namespace :merchandises do
  desc "Update promotion_start column for all merchandises"
  task update_promotion_start: :environment do
    Merchandise.find_each do |merchandise|
      promotion_start_date = merchandise.created_at.to_date + 10.days
      merchandise.update(promotion_start: promotion_start_date)
    end
    puts "All merchandise promotion_start dates have been updated."
  end
end
