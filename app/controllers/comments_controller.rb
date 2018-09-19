class CommentsController < ApplicationController
	before_action :set_comment, only: [:edit, :update, :destroy]

	# GET /comments
	# GET /comments.json
	def index
		@comments = Comment.order(name: :asc)
	end

	# GET /comments/new
	def new
		@comment = Comment.new(resource_id: params[:resource_id], resource_type: params[:resource_type])

		respond_to do |format|
			format.js
		end
	end

	# GET /comments/1/edit
	def edit
		respond_to do |format|
			format.js
		end
	end

	# POST /comments
	# POST /comments.json
	def create
		@comment = Comment.new(comment_params)
		if @comment.save
			render :create, locals: { comment: @comment }
		else
			render :new, locals: { comment: @comment }
		end
	end

	# PATCH/PUT /comments/1
	# PATCH/PUT /comments/1.json
	def update
		@comment.update_attributes(comment_params)
		if @comment.save
			render :update, locals: {comment: @comment}
		else
			render :edit, locals: {comment: @comment}
		end
	end

	# DELETE /comments/1
	# DELETE /comments/1.json
	def destroy
		@comment.destroy
		respond_to do |format|
			format.js
		end
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_comment
			@comment = Comment.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def comment_params
			params[:comment].each { |key, value| value.strip! }
      params[:comment][:resource_id] = params[:resource_id] if params[:resource_id]
      params[:comment][:resource_type] = params[:resource_type] if params[:resource_type]
			params.require(:comment).permit!
		end
end
