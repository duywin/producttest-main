namespace :elasticsearch do
  desc "Purge shard and index all Account records in Elasticsearch"
  task reindex_accounts: :environment do
    client = Account.__elasticsearch__.client
    index_name = Account.index_name

    # Purge existing index
    if client.indices.exists?(index: index_name)
      puts "Deleting existing index: #{index_name}"
      client.indices.delete(index: index_name)
    else
      puts "Index #{index_name} does not exist. No need to delete."
    end

    # Recreate the index with the correct mappings and settings
    puts "Creating new index: #{index_name}"
    Account.__elasticsearch__.create_index!(force: true)

    # Index all Account records
    Account.find_each do |account|
      puts "Indexing Account ID: #{account.id} - #{account.username}"
      account.__elasticsearch__.index_document(
        id: account.id,
        body: {
          username: account.username,
          email: account.email,
          created_at: account.created_at
        }
      )
    end

    puts "All Accounts indexed successfully."
  end
end
