namespace :elasticsearch do
  desc "Index all Account records in Elasticsearch, skipping duplicates"
  task index_accounts: :environment do
    Account.find_each do |account|
      if account.__elasticsearch__.client.exists?(index: Account.index_name, id: account.id)
        puts "Skipping Account ID: #{account.id} - #{account.username}, already indexed"
      else
        puts "Indexing Account ID: #{account.id} - #{account.username}"
        account.__elasticsearch__.index_document(
          id: account.id,  # Ensure we use the ID to avoid duplicates
          body: {
            username: account.username,
            email: account.email,
            created_at: account.created_at
          }
        )
      end
    end
    puts "All Accounts processed successfully."
  end
end
