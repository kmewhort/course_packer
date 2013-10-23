class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :assign_temp_user_id

  # allow ability checks on anonymous users
  def current_ability
    user = user_signed_in? ? current_user : nil
    @current_ability ||= Ability.new(user, session[:temp_user_id])
  end

  # after a devise sign-in/sign-up, need to check whether the user has already been working on any new coursepacks
  # that we need to associate with the account
  def after_sign_in_path_for(resource)
    CoursePack.where(owner_session_token: session[:temp_user_id], owner_id: nil).each do |cp|
      cp.owner = current_user
      cp.owner_session_token = nil
      cp.save
    end

    super
  end

  private
  # assign a temporary user id for anonymous users
  def assign_temp_user_id
    if !user_signed_in? && session[:temp_user_id].nil?
      session[:temp_user_id] = SecureRandom.hex
    end
  end

end
