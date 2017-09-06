msgstr = <<END_OF_MESSAGE
hengwen say hello to u
END_OF_MESSAGE

require 'net/smtp'
Net::SMTP.start('smtpcloud.sohu.com', 25, 'welcome@testerhome.com',
                'testchina', 'Z1OSFR5kqECP4gTX', :login) do |smtp|
  smtp.send_message msgstr,
                    'welcome@testerhome.com',
                    'lihuazhang@hotmail.com'
end
