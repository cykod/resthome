require 'resthome'
require 'digest/sha2'
require 'base64'

class AmazonSESService < RESTHome
  base_uri 'https://email.us-east-1.amazonaws.com'
  
  @@digest256 = OpenSSL::Digest::Digest.new("sha256")

  route :verify_email_address, '/', :body => {'Action' => 'VerifyEmailAddress', 'EmailAddress' => :arg1}, :method => :post, :expected_status => 200, :no_body => true do |res|
    res['VerifyEmailAddressResponse']
  end

  def initialize(access_key, secret)
    @access_key = access_key
    @secret = secret
  end

  def build_options!(options)
    date = Time.now.getutc.httpdate
    options[:headers] ||= {}
    options[:headers]['Date'] = date
    options[:headers]['X-Amzn-Authorization'] = "AWS3-HTTPS AWSAccessKeyId=#{@access_key},Algorithm=HMACSHA256,Signature=#{AmazonSESService.sign_request(@secret, date)}"
  end

  def self.sign_request(secret, date)
    Base64.encode64(OpenSSL::HMAC.digest(@@digest256, secret, date)).gsub("\n","")
  end
end
