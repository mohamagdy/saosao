class HomeController < ApplicationController
  def index
    if !session[:screen_name]
      # Saving the token and token secret for future use
      session[:oauth_token], session[:oauth_token_secret] = Twitter.obtain_request_token
      # Setting the twitter authentication url
      @login_url = "https://api.twitter.com/oauth/authenticate?oauth_token=" + session[:oauth_token]
    else
      page = params[:page] || 1
      @followees = Twitter.followees(session[:screen_name], page.to_i)
      @totals = Twitter.totals(session[:screen_name])
    end
  end

  def twitter_signin_callback
    # Checking if the tokens match
    if params[:oauth_token] == session[:oauth_token]
      # Getting the user's data (screen_name and user_id)
      user_data = Twitter.user_info(params[:oauth_verifier], session[:oauth_token])
      
      # Saving the user's tokens and the screen_name for future use
      session[:oauth_token] = user_data[:oauth_token] # For authenticated access
      session[:oauth_token_secret] = user_data[:oauth_token_secret] # For authenticated access
      session[:screen_name] = user_data[:screen_name]
      
      redirect_to root_path
    else
      # Hacking
      flash[:warning] = "Not authorized access!"
      redirect_to root_path
    end
  end
  
  def unfollow
    params[:followees_ids].each do |followee_id|
      Twitter.unfollow(session[:oauth_token], session[:oauth_token_secret], followee_id)
    end
    
    flash[:success] = "Successfully unfollowed #{params[:followees_ids].count} followee(s)!"
    redirect_to root_path
  end
  
  def search
    @users = Twitter.search(params[:search], params[:page] || 1)
  end
  
  def follow
    params[:users_screen_names].each do |user_screen_name|
      Twitter.follow(session[:oauth_token], session[:oauth_token_secret], user_screen_name)
    end
    
    flash[:success] = "Successfully followed #{params[:users_screen_names].count} followee(s)!"
    redirect_to root_path
  end
end
