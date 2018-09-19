class ProductsController < ApplicationController
	before_action :set_product, only: [:show, :edit, :update, :destroy]

	# GET /products
	# GET /products.json
	def index
		@products = if params[:client_id].present?
			@client = Client.find(params[:client_id].to_i)
			Product.where("client_id = ?", params[:client_id].to_i)
		else
			Product.all
		end
	end

	# GET /products/1
	# GET /products/1.json
	def show
	end

	# GET /products/new
	def new
		@product = if params[:client_id].present? || params[:product][:client_id]
			client_id = params[:client_id] || params[:product][:client_id]
			@client = Client.find(client_id.to_i)
			Product.new(client_id: client_id.to_i)
		else
			Product.new
		end
	end

	# GET /products/1/edit
	def edit
		@client = @product.client
	end

	# POST /products
	# POST /products.json
	def create
		@product = Product.new(product_params)

		respond_to do |format|
			if @product.save
        link = client_client_landing_pages_path(client_id: @product.client.id)
        notice = 'Product and landing page were successfully created. Please edit landing page!'
        if @product.client.ignore_landing_pages
          link = client_representatives_path(client_id: @product.client.id)
          notice = 'Product was successfully created!'
        end
				format.html { redirect_to link, notice: notice }
				format.json { render action: 'show', status: :created, location: @product }
			else
				@client = Client.find(@product.client_id)
				format.html { render action: 'new' }
				format.json { render json: @product.errors, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /products/1
	# PATCH/PUT /products/1.json
	def update
		respond_to do |format|
			if @product.update(product_params)
				format.html { redirect_to client_products_path(client_id: @product.client.id), notice: 'Product was successfully updated.' }
				format.json { head :no_content }
			else
				@client = Client.find(@product.client_id)
				format.html { render action: 'edit' }
				format.json { render json: @product.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /products/1
	# DELETE /products/1.json
	def destroy
		@product.destroy
		respond_to do |format|
			format.html { redirect_to client_products_path(client_id: @product.client.id) }
			format.json { head :no_content }
		end
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_product
			@product = Product.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def product_params
		 params.require(:product).permit!
		end
end
