namespace :elasticsearch do
  desc "Purge shard and index all Cart records in Elasticsearch"
  task reindex_carts: :environment do
    client = Cart.__elasticsearch__.client
    index_name = Cart.index_name

    # Purge existing index
    if client.indices.exists?(index: index_name)
      puts "Deleting existing index: #{index_name}"
      client.indices.delete(index: index_name)
    else
      puts "Index #{index_name} does not exist. No need to delete."
    end

    # Recreate the index with the correct mappings and settings
    puts "Creating new index: #{index_name}"
    Cart.__elasticsearch__.create_index!(force: true)

    # Index all Cart records
    Cart.find_each do |cart|
      puts "Indexing Cart ID: #{cart.id}"
      cart.__elasticsearch__.index_document(
        id: cart.id,
        body: {
          account_id: cart.account_id,
          status: cart.status,
          deliver_day: cart.deliver_day,
          created_at: cart.created_at
        }
      )
    end

    puts "All Carts indexed successfully."
  end
end
