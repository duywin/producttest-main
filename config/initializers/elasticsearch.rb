# config/initializers/elasticsearch.rb
Elasticsearch::Model.client = Elasticsearch::Client.new(
  host: "localhost:9200",
  transport_options: {
    request: {timeout: 250}
  },
  log: true, # Set to true to log Elasticsearch requests for debugging
  retry_on_failure: 3, # Retry up to 3 times on failure
  ping_timeout: 5 # Timeout for pinging Elasticsearch
)
