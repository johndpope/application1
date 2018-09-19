class Sandbox::HomeController < Sandbox::BaseController
	def index
		@categories = Sandbox::ClientCategory.order(:name)
	end

	def how_it_works
	end
end
