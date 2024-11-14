# config/initializers/grover.rb
Grover.configure do |config|
  # Middleware settings
  config.use_png_middleware = true
  config.use_jpeg_middleware = true
  config.use_pdf_middleware = false

  # Grover rendering options
  config.options = {
    wait_until: 'networkidle0', # Ensures that Grover waits until the network is idle (all data is fetched)
    timeout: 60000,             # Increase timeout to allow more time for rendering
    # other options...
  }
end
