# Resources
# https://dev.twitter.com/docs/auth/implementing-sign-twitter
# http://www.drcoen.com/2011/12/oauth-with-the-twitter-api-in-ruby-on-rails-without-a-gem/

require 'securerandom'
require 'oauth.rb'

class Twitter
  include OAuth
  
  # This method returns the consumer key of the Twitter Application 
  def self.consumer_key
    "foYiMY2ouuF3Mi41K7bdQ"    
  end
  
  # This method returns the consumer secret key of the Twitter Application
  def self.consumer_secret
    "uwaSET81cDSLyMdkxY7oTwt1HzLKUkTVHWi1jSlDSWo"
  end 
  
  # This method  returns the callback url which will be the url the application
  # redirected to after signing in
  def self.callback_url
    "http://localhost:3000/twitter_signin_callback"
  end
  
  # This method populates the parameters to be sent to Twitter, some parameters could be added later
  def self.params
    { 
      :oauth_consumer_key => Twitter.consumer_key,
      :oauth_nonce => SecureRandom.hex, # Random 64-bit, unsigned number encoded as an ASCII string in decimal format
      :oauth_signature_method => "HMAC-SHA1",
      :oauth_timestamp => Time.now.to_i.to_s,
      :oauth_version => "1.0"
    }
  end
  
  # Step 1: Obtaining a request token (the same as step 1 in https://dev.twitter.com/docs/auth/implementing-sign-twitter)
  def self.obtain_request_token
    method = "POST"
    uri = "https://api.twitter.com/oauth/request_token"
    params = Twitter.params
    params[:oauth_callback] = OAuth.url_encode(Twitter.callback_url)
    params[:oauth_signature] = OAuth.url_encode(OAuth.sign(Twitter.consumer_secret + '&', OAuth.signature_base_string(method, uri, params)))
    token_data = parse_response(OAuth.request_data(OAuth.header(params), uri, method))
    auth_token, auth_token_secret = [token_data[:oauth_token], token_data[:oauth_token_secret]] # save these values, they'll be used again later

  end
  
  # Step 2: Getting the user's info using the access token (oauth_verifier)
  # and the auth_token (Step 3 in https://dev.twitter.com/docs/auth/implementing-sign-twitter)
  def self.user_info(access_token, auth_token)
    method = "POST"
    uri = "https://api.twitter.com/oauth/access_token"
    params = Twitter.params
    params[:oauth_verifier] = access_token 
    params[:oauth_token] = auth_token
    params[:oauth_signature] = OAuth.url_encode(OAuth.sign(Twitter.consumer_secret + '&', OAuth.signature_base_string(method, uri, params)))
    data = parse_response(OAuth.request_data(OAuth.header(params), uri, method))
  end
  
  private
  # Parsing the response
  def self.parse_response(str)
    ret = {}
    str.split('&').each do |pair|
      key_and_val = pair.split('=')
      ret[key_and_val[0].to_sym] = key_and_val[1]
    end
    ret
  end
end