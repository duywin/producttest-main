namespace :elasticsearch do
  desc "Purge shard and index all Product records in Elasticsearch"
  task reindex_products: :environment do
    client = Product.__elasticsearch__.client
    index_name = Product.index_name

    # Purge existing index
    if client.indices.exists?(index: index_name)
      puts "Deleting existing index: #{index_name}"
      client.indices.delete(index: index_name)
    else
      puts "Index #{index_name} does not exist. No need to delete."
    end

    # Recreate the index with the correct mappings and settings
    puts "Creating new index: #{index_name}"
    Product.__elasticsearch__.create_index!(force: true)

    # Index all Product records
    Product.find_each do |product|
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

    puts "All Products indexed successfully."
  end
end
