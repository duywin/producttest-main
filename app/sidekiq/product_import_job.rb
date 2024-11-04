class ProductImportJob < ApplicationJob
  queue_as :default

  def perform(file_path)
    products = import_products_from_file(file_path)
    if products.is_a?(String)
      Rails.logger.error("Product import error: #{products}")
    else
      Product.import(products)
      Rails.logger.info("#{products.size} products were successfully imported.")
    end
  end

  private

  def import_products_from_file(file_path)
    spreadsheet = Roo::OpenOffice.new(file_path)
    header = spreadsheet.row(1)
    products = []

    (2..spreadsheet.last_row).each do |i|
      row = spreadsheet.row(i)
      Rails.logger.info("Processing row: #{row.inspect}")  # Log the row being processed
      product = create_product_from_row(row, header)

      if product.valid? # Ensure the product is valid before adding
        products << product
      else
        Rails.logger.error("Invalid product: #{product.errors.full_messages.join(', ')}") # Log any errors
      end
    end

    products
  rescue StandardError => e
    Rails.logger.error("Error reading file: #{e.message}")  # Log errors while reading the file
    "Error reading file: #{e.message}"
  end


  def create_product_from_row(row, header)
    default_values = {
      desc: 'No description available.',
      stock: 0,
      picture: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRfCIpb4DjTLc26hfSl7YKW6bf07zz38YcyHQ&s'
    }

    product_attributes = {
      name: row[header.index('name')] || default_values[:name],
      product_type: row[header.index('product_type')] || 'Default Type',
      prices: row[header.index('prices')] || 0.00,
      desc: row[header.index('desc')] || default_values[:desc],
      stock: row[header.index('stock')] || default_values[:stock],
      picture: row[header.index('picture')] || default_values[:picture]
    }

    Product.new(product_attributes) # Return the product instance
  end
end
