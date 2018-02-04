class PhotoUploader < BaseUploader
  include CarrierWave::MiniMagick

  process :add_text


  # Override the filename of the uploaded files:
  def filename
    if super.present?
      @name ||= SecureRandom.uuid
      "#{Time.now.year}/#{@name}.#{file.extension.downcase}"
    end
  end

  def watermark
    watermark = "#{Rails.root}/app/assets/images/favicon.png"
    manipulate! do |img|
      img = img.composite(MiniMagick::Image.open(watermark), "png") do |c|
        c.gravity "SouthWest"
      end
    end
  end

  def add_text
    manipulate! do |image|
      height = image.height
      size = height * (0.002) * 20
      image.combine_options do |c|
        c.gravity 'southwest'
        c.pointsize "#{size}"
        c.draw "text 0,0 'testerhome.com'"
        c.fill '#ccc'
      end
      image
    end
  end

end
