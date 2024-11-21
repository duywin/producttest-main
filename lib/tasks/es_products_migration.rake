namespace :elasticsearch do
  desc "Index all Product records in Elasticsearch, skipping duplicates"
  task index_products: :environment do
    Product.find_each do |product|
      if product.__elasticsearch__.client.exists?(index: Product.index_name, id: product.id)
        puts "Skipping Product ID: #{product.id} - #{product.name}, already indexed"
      else
        puts "Indexing Product ID: #{product.id} - #{product.name}"

        product.__elasticsearch__.index_document(
          id: product.id,
          body: {
            id: product.id,
            name: product.name,
            product_type: product.product_type,
            prices: product.prices
          }
        )
      end
    end

    puts "All Products processed successfully."
  end
end
