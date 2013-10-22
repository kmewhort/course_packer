class Ability
  include CanCan::Ability

  def initialize(user, session_token)
    # logged-in users
    if !user.nil?
      if user.has_role? :admin
        can :manage, :all
      else
        # can read and write own course packs
        can :manage, CoursePack, owner_id: user.id
      end

    # anonymous users
    else
      # can read and write own course packs
      can :manage, CoursePack, owner_session_token: session_token
    end

    # all users (including anonymous) can view any course pack for which they have the URL, and create a new course pack,
    can [:show, :new], CoursePack
  end
end
