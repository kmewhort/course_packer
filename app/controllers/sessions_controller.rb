class SessionsController < Devise::SessionsController
  def create
    super

    # after sign-in, check if the user has already been working on any new coursepacks that we need to associate with the account
    unless session[:temp_user_id].nil?
      CoursePack.where(owner_session_token: session[:temp_user_id], owner_id: nil).each do |cp|
        cp.owner = current_user
        cp.owner_session_token = nil
        cp.save
      end
    end
  end
end