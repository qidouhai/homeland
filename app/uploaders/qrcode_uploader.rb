# coding: utf-8
class QrcodeUploader < BaseUploader
  def filename
    if super.present?
      "qrcode/#{model.id}.jpg"
    end
  end
end
