# Resources
# https://dev.twitter.com/docs/auth/implementing-sign-twitter
# http://www.drcoen.com/2011/12/oauth-with-the-twitter-api-in-ruby-on-rails-without-a-gem/
# https://dev.twitter.com/docs/api

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
  
  # This method returns the followees of a given user
  # The screen_name is the user's Twitter username and 
  # page is the page number (used in pagination) 
  def self.followees(screen_name, page=1)
    method = "GET"
    uri = "https://api.twitter.com/1/friends/ids.json"
    params = Twitter.params
    params[:cursor] = -1 # start at the beginning
    params[:screen_name] = screen_name # from 'data' array above
    params[:oauth_signature] = OAuth.url_encode(OAuth.sign(Twitter.consumer_secret + '&', OAuth.signature_base_string(method, uri, params)))
    
    # Each page has 20 records and the maximum number of ids
    # returned from the /friends/ids.json is 5000 that's why 250 (5000 / 20).
    # To load the next records, Twitter sends a parameter called "next_cursor" to paginate 
    # to the next 5000 record so we made our pagination according to to the
    # page parameter passed to this method.
    curser_forwarding_count = (page.to_f / 250).ceil
    cursor = -1
    data = nil
    
    (1..curser_forwarding_count).each do
      request_uri = uri + "?cursor=#{cursor}&screen_name=#{screen_name}"
      data = JSON.parse(OAuth.request_data(OAuth.header(params), request_uri, method))
      cursor = data["next_cursor"]
    end
    
    # Sending the page's records
    Twitter.followees_info(data["ids"][page * 20 - 20 ... page * 20].join(","))
  end
  
  # This method fetches the followees info using the users/lookup.json
  def self.followees_info(followees_ids)
    method = "GET"
    uri = "https://api.twitter.com/1/users/lookup.json"
    params = Twitter.params
    params[:oauth_signature] = OAuth.url_encode(OAuth.sign(Twitter.consumer_secret + '&', OAuth.signature_base_string(method, uri, params)))
    uri += "?user_id=#{followees_ids}" # Add in the GET parameters to the URL
    JSON.parse(OAuth.request_data(OAuth.header(params), uri, method))   
  end
  
  # This method returns the number of followees and followers the user
  # whose screen name is passed as a parameter to the method
  def self.totals(screen_name)
    method = "GET"
    uri = "https://api.twitter.com/1/users/lookup.json"
    params = Twitter.params
    params[:oauth_signature] = OAuth.url_encode(OAuth.sign(Twitter.consumer_secret + '&', OAuth.signature_base_string(method, uri, params)))
    uri += "?screen_name=#{screen_name}"
    data = JSON.parse(OAuth.request_data(OAuth.header(params), uri, method))
    {:followees => data.first["followers_count"], :followers => data.first["friends_count"]} 
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