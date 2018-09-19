class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    alias_action :create, :read, :update, :destroy, :to => :crud

    user ||= AdminUser.new # guest user (not logged in)

    send(user.roles)

    default_access_rights if user.roles.blank?

    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end

  def content_manager
    can :manage, :all
    cannot :manage, [AdminUser,TechnicalAccount,NoIpEmail,GoogleApiClient,
        GoogleApiClient,GoogleApiProject,GooglePlusAccount,Client,
        ApiOperation,Delayed::Job,DeleteYoutubeVideo,UploadYoutubeVideo,UploadYoutubeVideoThumbnail]
    can :read, [ApiOperation,BroadcastStream,Delayed::Job,DeleteYoutubeVideo,UploadYoutubeVideo,UploadYoutubeVideoThumbnail]
    can :read, Client
  end

  def google_accounts_manager
    can :manage, GoogleAccount
  end

  def admin
    can :manage, :all
  end

  def default_access_rights
    can :manage, :all
    can :read, ActiveAdmin::Page, :name => "Dashboard"
    can :read, :all
    cannot :manage, [AdminUser,GoogleAccount,TechnicalAccount,NoIpEmail,GoogleApiClient,
        GoogleApiClient,GoogleApiProject,GooglePlusAccount,Client,
        ApiOperation,BroadcastStream,Delayed::Job,DeleteYoutubeVideo,UploadYoutubeVideo,UploadYoutubeVideoThumbnail]
  end
end
