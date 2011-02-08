require 'resthome'

class TwilioWebService < RESTHome
  base_uri 'https://api.twilio.com'

  namespace '/2010-04-01' do
    route :accounts, '/Accounts'

    namespace '/Accounts' do
      route :create_sms_message, '/:sid/SMS/Messages', :expected_status => 201 do |res|
        res['TwilioResponse']['SMSMessage']
      end
    end
  end

  attr_accessor :number

  def initialize(account_sid, auth_token, number)
    @number = number
    self.basic_auth = {:username => account_sid, :password => auth_token}
  end

  def self.service
    config = YAML.load_file("#{Rails.root}/config/twilio.yml")
    TwilioWebService.new config['twilio']['sid'], config['twilio']['token'], config['twilio']['number']
  end

  def send_sms_message(cell_phone, message)
    self.create_sms_message self.basic_auth[:username], {'From' => @number, 'To' => cell_phone, 'Body' => message}
  end
end
