class HomeController < ApplicationController
  def index
    unless session[:screen_name]
      # Saving the token and token secret for future use
      session[:oauth_token], session[:oauth_token_secret] = Twitter.obtain_request_token
      # Setting the twitter authentication url
      @login_url = "https://api.twitter.com/oauth/authenticate?oauth_token=" + session[:oauth_token]
    end
  end

  def twitter_signin_callback
    # Checking if the tokens match
    if params[:oauth_token] == session[:oauth_token]
      # Getting the user's data (screen_name and user_id)
      user_data = Twitter.user_info(params[:oauth_verifier], session[:oauth_token])
      # Saving the screen_name for future use
      session[:screen_name] = user_data[:screen_name]
      redirect_to root_path
    else
      # Hacking
      flash[:warning] = "Not authorized access!"
      redirect_to root_path
    end
  end
end
