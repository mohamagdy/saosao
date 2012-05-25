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
    APP_CONFIG["consumer_key"]
  end
  
  # This method returns the consumer secret key of the Twitter Application
  def self.consumer_secret
    APP_CONFIG["consumer_secret"]
  end 
  
  # This method  returns the callback url which will be the url the application
  # redirected to after signing in
  def self.callback_url
    APP_CONFIG["callback_url"]
  end
  
  # This method populates the parameters to be sent to Twitter, some parameters could be added later
  def self.params
    { 
      :oauth_consumer_key => Twitter.consumer_key,
      :oauth_nonce => SecureRandom.hex, # Random 64-bit, unsigned number encoded as an ASCII string in decimal format
      :oauth_signature_method => "HMAC-SHA1",
      :oauth_timestamp => Time.now.getutc.to_i.to_s,
      :oauth_version => "1.0"
    }
  end
  
  # Step 1: Obtaining a request token (the same as step 1 in https://dev.twitter.com/docs/auth/implementing-sign-twitter)
  def self.obtain_request_token
    token_data = parse_response(Twitter.send_request("POST", "https://api.twitter.com/oauth/request_token", 
                               {:oauth_callback => OAuth.url_encode(Twitter.callback_url)}))
                               
    auth_token, auth_token_secret = [token_data[:oauth_token], token_data[:oauth_token_secret]] # save these values, they'll be used again later
  end
  
  # Step 2: Getting the user's info using the access token (oauth_verifier)
  # and the auth_token (Step 3 in https://dev.twitter.com/docs/auth/implementing-sign-twitter)
  def self.user_info(access_token, auth_token)
    parse_response(Twitter.send_request("POST", "https://api.twitter.com/oauth/access_token", 
                   {:oauth_verifier => access_token, :oauth_token => auth_token, }))
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
    # page parameter passed to this method. This could be a perfect example 
    # https://api.twitter.com/1/followers/ids.json?screen_name=ESET&cursor=-1
    curser_forwarding_count = (page / 250.0).ceil
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
    data = JSON.parse(Twitter.send_request("GET", "https://api.twitter.com/1/users/lookup.json?user_id=#{followees_ids}"))
    data.is_a?(Hash) && data.has_key?("errors") ? [] : data   
  end
  
  # This method returns the number of followees and followers the user
  # whose screen name is passed as a parameter to the method
  def self.totals(screen_name)
    data = JSON.parse(Twitter.send_request("GET", "https://api.twitter.com/1/users/lookup.json?screen_name=#{screen_name}"))
    {:followees => data.first["followers_count"], :followers => data.first["friends_count"]} 
  end
  
  # This method used to unfollow a user. The given parameters are
  # auth_token: the auth_token of the currently logged in user
  # auth_token_secret: the secret auth_token of the currently logged in user
  # followee_id: the id of the followee to be unfollowed
  # The method used is POST and this action requires authentication
  def self.unfollow(auth_token, auth_token_secret, followee_id)
    JSON.parse(Twitter.send_request("POST", "https://api.twitter.com/1/friendships/destroy.json",
    {:user_id => followee_id, :oauth_token => auth_token}, "user_id=" + followee_id, auth_token_secret))
  end
  
  # This method uses the Twitter's tweets search API. The params are
  # the query string, the screen_name of the current user and the page number
  def Twitter.search(query, current_user_screen_name, page=1)
    # Retreiving all the tweets matching the query string
    tweets = JSON.parse(Twitter.send_request("GET", "http://search.twitter.com/search.json?q=#{OAuth.url_encode(query)}&page=#{page}&rpp=20"))
                        
    # Fetching the users created these tweets and calling the uniq method to remove duplicates
    users_screen_names = tweets["results"].inject([]){|users, result| users << result["from_user"]}.uniq
    
    # Ignoring the users who have friendship with the current user
    Twitter.check_friendship(users_screen_names, current_user_screen_name)
  end
  
  # This method checks if the users with screen names given in the
  # users_screen_names array have friendship with the user with
  # screen name  current_user_screen_name
  def self.check_friendship(users_screen_names, current_user_screen_name)
    users_screen_names.inject([]) do |users, user_screen_name|
      friendship_exists = Twitter.send_request("GET", "https://api.twitter.com/1/friendships/exists.json?screen_name_a=#{user_screen_name}&screen_name_b=#{current_user_screen_name}")
      
      users << user_screen_name if friendship_exists == "false"
    end
  end
  
  # This method used to follow a user. The given parameters are
  # auth_token: the auth_token of the currently logged in user
  # auth_token_secret: the secret auth_token of the currently logged in user
  # user_screen_name: the screen name of the user to be followed
  # The method used is POST and this action requires authentication
  def self.follow(auth_token, auth_token_secret, user_screen_name)
    JSON.parse(Twitter.send_request("POST", "https://api.twitter.com/1/friendships/create.json",
    {:screen_name => user_screen_name, :oauth_token => auth_token}, "screen_name=" + user_screen_name, auth_token_secret))
  end
  
  # This method is used to sign out a logged in user from Twitter
  # The method takes the auth_token and the secret auth_token of the 
  # logged in user
  def self.sign_out(auth_token, auth_token_secret)
    JSON.parse(Twitter.send_request("POST", "https://api.twitter.com/1/account/end_session.json",
    {:oauth_token => auth_token}, nil, auth_token_secret))
  end
  
  private
  
  # This method sends the request to Twitter and returns the response. This method is implemented to DRY the code
  # as the lines in the methods were repeated in all the methods that sends a request to Twitter.
  def Twitter.send_request(method, uri, additional_params={}, additional_post_params=nil, auth_token_secret="")
    params = Twitter.params
    
    additional_params.each_pair do |key, value|
      params[key] = value
    end

    params[:oauth_signature] = OAuth.url_encode(OAuth.sign(Twitter.consumer_secret + '&' + auth_token_secret, OAuth.signature_base_string(method, uri, params)))
    OAuth.request_data(OAuth.header(params), uri, method, additional_post_params)
  end
  
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