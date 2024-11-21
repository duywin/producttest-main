namespace :elasticsearch do
  desc "Index all Cart records in Elasticsearch, skipping duplicates"
  task index_carts: :environment do
    Cart.find_each do |cart|
      if cart.__elasticsearch__.client.exists?(index: Cart.index_name, id: cart.id)
        puts "Skipping Cart ID: #{cart.id}, already indexed"
      else
        puts "Indexing Cart ID: #{cart.id}"
        cart.__elasticsearch__.index_document(
          id: cart.id,  # Ensure we use the ID to avoid duplicates
          body: {
            account_id: cart.account_id,
            status: cart.status,
            deliver_day: cart.deliver_day,
            created_at: cart.created_at
          }
        )
      end
    end
    puts "All Carts processed successfully."
  end
end
