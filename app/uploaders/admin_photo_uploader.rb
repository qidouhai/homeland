# frozen_string_literal: true

class AdminPhotoUploader < BaseUploader
  include CarrierWave::MiniMagick

  # Override the filename of the uploaded files:
  def filename
    if super.present?
      @name ||= SecureRandom.uuid
      "#{Time.now.year}/#{@name}.#{file.extension.downcase}"
    end
  end

  def store_dir
     "uploads/photo"
  end

end
