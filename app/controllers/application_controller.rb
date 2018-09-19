class ApplicationController < ActionController::Base
	include DataPage
	before_action :authenticate_admin_user!

	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception, unless: -> { request.format.json? }

	#unset scope_current_client as a part of temporary multitenancy disabling. It should be uncommented when the problem with multitenancy is solved
	#around_filter :scope_current_client

	rescue_from CanCan::AccessDenied do |exception|
		access_denied
	end

	def access_denied(exception)
		flash[:error] = 'Access denied.'
		redirect_to root_url
	end

	def set_current_user(user)
	@current_user=user
	end

	def current_ability
	@current_ability ||= Ability.new(current_user)
	end

	def current_user
		@current_user
	end

	def after_sign_in_path_for(resource)
		stored_location = stored_location_for(resource)
		stored_location.nil? || stored_location == '/admin' ? '/' : stored_location
	end

	private
		def current_client
			current_admin_user.try(:client)
		end

		def scope_current_client
			Client.current_id = current_client.try(:id)
			yield
		ensure
			Client.current_id = nil
		end

	protected
		def user_for_paper_trail
			if admin_user_signed_in?
				current_admin_user.email
			else
				nil
			end
		end
end
