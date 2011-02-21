require 'resthome'
require 'digest/sha2'
require 'base64'

class AmazonProductWebService < RESTHome
  base_uri 'http://ecs.amazonaws.com'

  DEFAULT_VERSION = '2009-03-31'

  @@digest256 = OpenSSL::Digest::Digest.new("sha256")

  attr_accessor :version, :access_key, :secret, :associate_tag

  namespace '/onca' do
    route :item_search, '/xml', :query => {'Keywords' => :arg1, 'SearchIndex' => :arg2, 'Operation' => 'ItemSearch', 'Service' => 'AWSECommerceService'} do |res|
      res['ItemSearchResponse']['Items']['Item']
    end

    route :item_lookup, '/xml', :query => {'ItemId' => :arg1, 'Operation' => 'ItemLookup', 'Service' => 'AWSECommerceService', 'ResponseGroup' => 'Small'} do |res|
      res['ItemLookupResponse']['Items']['Item']
    end
  end

  def initialize(access_key, secret)
    @access_key = access_key
    @secret = secret
    @version = DEFAULT_VERSION
    @host = URI.parse(self.class.base_uri).host
  end

  def build_options!(options)
    options[:query] ||= {}
    options[:query]['AWSAccessKeyId'] = @access_key
    options[:query]['Version'] = @version
    options[:query]['Timestamp'] = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    options[:query]['AssociateTag'] = self.associate_tag if self.associate_tag
  end

  def sign_request(method, path, options)
    signed_query = self.class.sign_request_v2(@secret, options[:query], method, @host, path)
    options.delete :query
    signed_query
  end

  def aws_request(method, path, options)
    build_options! options
    url = build_url(path)
    signed_query = sign_request(method, path, options)
    if method == :post
      options[:body] = signed_query
    else
      url += "?#{signed_query}"
    end

    @request_method = method
    @request_url = url
    @request_options = options

    @response = self.class.send(method, url, options)
  end

  alias_method :original_request, :request
  alias_method :request, :aws_request

  # copied from RightAws::AwsUtils
  def self.amz_escape(param)
    param.to_s.gsub(/([^a-zA-Z0-9._~-]+)/n) do
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
    end
  end

  # copied from RightAws::AwsUtils
  def self.sign_request_v2(aws_secret_access_key, service_hash, http_verb, host, uri)
    canonical_string = service_hash.keys.sort.map do |key|
      "#{self.amz_escape(key)}=#{self.amz_escape(service_hash[key])}"
    end.join('&')

    string_to_sign = "#{http_verb.to_s.upcase}\n#{host.downcase}\n#{uri}\n#{canonical_string}"

    signature = self.amz_escape(Base64.encode64(OpenSSL::HMAC.digest(@@digest256, aws_secret_access_key, string_to_sign)).strip)

    "#{canonical_string}&Signature=#{signature}"
  end
end
