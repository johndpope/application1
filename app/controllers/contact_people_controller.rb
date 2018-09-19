class ContactPeopleController < ApplicationController
	before_action :set_contact_person, only: [:edit, :update, :destroy]

	# GET /contact_persons
	# GET /contact_persons.json
	def index
		@contact_persons = ContactPerson.order(name: :asc)
	end

	# GET /contact_persons/new
	def new
		@contact_person = ContactPerson.new(resource_id: params[:resource_id], resource_type: params[:resource_type])

		respond_to do |format|
			format.js
		end
	end

	# GET /contact_persons/1/edit
	def edit
		respond_to do |format|
			format.js
		end
	end

	# POST /contact_persons
	# POST /contact_persons.json
	def create
		@contact_person = ContactPerson.new(contact_person_params)
		if @contact_person.save
			render :create, locals: { contact_person: @contact_person }
		else
			render :new, locals: { contact_person: @contact_person }
		end
	end

	# PATCH/PUT /contact_persons/1
	# PATCH/PUT /contact_persons/1.json
	def update
		@contact_person.update_attributes(contact_person_params)
		if @contact_person.save
			render :update, locals: {contact_person: @contact_person}
		else
			render :edit, locals: {contact_person: @contact_person}
		end
	end

	# DELETE /contact_persons/1
	# DELETE /contact_persons/1.json
	def destroy
		@contact_person.destroy
		respond_to do |format|
			format.js
		end
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_contact_person
			@contact_person = ContactPerson.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def contact_person_params
			params[:contact_person].each { |key, value| value.strip! }
      params[:contact_person][:resource_id] = params[:resource_id] if params[:resource_id]
      params[:contact_person][:resource_type] = params[:resource_type] if params[:resource_type]
			params.require(:contact_person).permit!
		end
end
