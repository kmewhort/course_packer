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

    # all users, including anonymous users, can view any course pack for which has a privacy setting of 'limited' or 'public'
    # (if they have the URL)
    can [:show, :prepare_preview, :preview, :print_selection, :print], CoursePack, sharing: ['public','link']

    # all users can create a new course pack
    can :new, CoursePack
  end
end
