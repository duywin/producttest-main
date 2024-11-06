# app/uploaders/picture_uploader.rb
class PictureUploader < CarrierWave::Uploader::Base
  # Choose storage method: :file or :fog (for cloud storage)
  storage :file

  # Only allow images
  def extension_white_list
    %w[jpg jpeg gif png]
  end

  # You can customize the file path
  def store_dir
    "uploads/products/pictures/#{model.id}" # Store in a directory based on the product ID
  end
end
