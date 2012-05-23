# Resources
# http://www.drcoen.com/2011/12/oauth-with-the-twitter-api-in-ruby-on-rails-without-a-gem/

require 'net/http'
require 'net/https'

module OAuth
  def sign(key, base_string)
    digest = OpenSSL::Digest::Digest.new('sha1')
    hmac = OpenSSL::HMAC.digest(digest, key, base_string)
    Base64.encode64(hmac).chomp.gsub(/\n/, '')
  end
  
  def url_encode(string)
    CGI::escape(string)
  end
  
  def signature_base_string(method, uri, params)
    encoded_params = params.sort.collect{ |k, v| url_encode("#{k}=#{v}") }.join('%26')
    method + '&' + url_encode(uri) + '&' + encoded_params
  end
  
  def header(params)
    header = "OAuth "
    params.each do |k, v|
      header += "#{k}=\"#{v}\", "
    end
    header.slice(0..-3) # removing the last ", "
  end
  
  def request_data(header, base_uri, method, post_data=nil)
    url = URI.parse(base_uri)
    http = Net::HTTP.new(url.host, 443) # set to 80 if not using HTTPS
    http.use_ssl = true # ignore if not using HTTPS
    if method == 'POST'
      resp, data = http.post(url.path, post_data, { 'Authorization' => header })
    else
      resp, data = http.get(url.to_s, { 'Authorization' => header })
    end
    resp.body
  end
  
  module_function :sign, :url_encode, :signature_base_string, :header, :request_data
end