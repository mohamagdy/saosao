require 'openssl'
require 'digest/sha1'

class HomeController < ApplicationController
  
  # GET /
  def index
    if !session[:screen_name]
      # Saving the token and token secret for future use
      session[:oauth_token], oauth_token_secret = Twitter.obtain_request_token
      
      # Setting the twitter authentication url
      @login_url = "https://api.twitter.com/oauth/authenticate?oauth_token=" + session[:oauth_token]
    else
      page = params[:page] || 1
      @followees = Twitter.followees(session[:screen_name], page.to_i)
      @totals = Twitter.totals(session[:screen_name])
    end
  end

  # GET /twitter_signin_callback
  def twitter_signin_callback
    # Checking if the tokens match
    if params[:oauth_token] == session[:oauth_token]
      # Getting the user's data (screen_name and user_id)
      user_data = Twitter.user_info(params[:oauth_verifier], session[:oauth_token])
      
      # Creating a random_iv to be used in the encryption process
      session[:random_iv] = OpenSSL::Cipher::Cipher.new("aes-256-cbc").random_iv
      
      # Encrypting the attributes for security reasons
      encrypt_session_attribute(user_data[:screen_name], :oauth_token, user_data[:oauth_token])
      encrypt_session_attribute(user_data[:screen_name], :oauth_token_secret, user_data[:oauth_token_secret])

      session[:screen_name] = user_data[:screen_name]
      
      redirect_to root_path
    else
      # Hacking
      flash[:warning] = "Not authorized access!"
      redirect_to root_path
    end
  end
  
  # POST /unfollow
  def unfollow
    # Decrypting the attributes
    oauth_token = decrypt_session(session[:screen_name], :oauth_token)
    oauth_token_secret = decrypt_session(session[:screen_name], :oauth_token_secret)
    
    params[:followees_ids].each do |followee_id|
      Twitter.unfollow(oauth_token, oauth_token_secret, followee_id)
    end
    
    flash[:success] = "Successfully unfollowed #{params[:followees_ids].count} followee(s)!"
    redirect_to root_path
  end
  
  # POST /search
  def search
    @users = Twitter.search(params[:search], session[:screen_name], params[:page] || 1)
  end
  
  # POST /follow
  def follow
    # Decrypting the attributes
    oauth_token = decrypt_session(session[:screen_name], :oauth_token)
    oauth_token_secret = decrypt_session(session[:screen_name], :oauth_token_secret)
    
    params[:users_screen_names].each do |user_screen_name|
      Twitter.follow(oauth_token, oauth_token_secret, user_screen_name)
    end
    
    flash[:success] = "Successfully followed #{params[:users_screen_names].count} followee(s)!"
    redirect_to root_path
  end
  
  # GET /sign_out
  def sign_out
    # Decrypting the attributes
    oauth_token = decrypt_session(session[:screen_name], :oauth_token)
    oauth_token_secret = decrypt_session(session[:screen_name], :oauth_token_secret)
    
    # Signing out from Twitter
    Twitter.sign_out(oauth_token, oauth_token_secret)
    
    # Clearing the user's data saved in the session
    session.delete(:oauth_token)
    session.delete(:oauth_token_secret)
    session.delete(:screen_name)
    session.delete(:random_iv)
    
    flash[:success] = "Signed out sucessfully!"
    redirect_to root_path
  end
  
  private
  def encrypt_session_attribute(user_screen_name, session_attribute_name, session_attribute_value)
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.encrypt
    
    cipher.key = Digest::SHA1.hexdigest(user_screen_name)
    cipher.iv = session[:random_iv]
    
    # encrypt the message
    encrypted = cipher.update(session_attribute_value)
    encrypted << cipher.final
    
    cipher.decrypt
    
    cipher.key = Digest::SHA1.hexdigest(user_screen_name)

    session[session_attribute_name] = encrypted
  end
  
  def decrypt_session(user_screen_name, session_attribute_name)
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.decrypt
    
    cipher.key = Digest::SHA1.hexdigest(user_screen_name)
    cipher.iv = session[:random_iv]
    
    # and decrypt it
    decrypted = cipher.update(session[session_attribute_name])
    decrypted << cipher.final
  end
end
