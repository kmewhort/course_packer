class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :assign_temp_user_id

  # allow ability checks on anonymous users
  def current_ability
    user = user_signed_in? ? current_user : nil
    @current_ability ||= Ability.new(user, session[:temp_user_id])
  end

  private
  # assign a temporary user id for anonymous users
  def assign_temp_user_id
    if !user_signed_in? && session[:temp_user_id].nil?
      session[:temp_user_id] = SecureRandom.hex
    end
  end

end
