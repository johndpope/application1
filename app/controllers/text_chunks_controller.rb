class TextChunksController < ApplicationController
	before_action :set_text_chunk, only: [:edit, :update, :destroy]
	TEXT_CHUNKS_DEFAULT_LIMIT = 25

	def index
		params[:limit] = TEXT_CHUNKS_DEFAULT_LIMIT unless params[:limit].present?

		if params[:filter].present?
			params[:filter][:order] = 'created_at' unless params[:filter][:order].present?
			params[:filter][:order_type] = 'asc' unless params[:filter][:order_type].present?
		else
			params[:filter] = { order: 'updated_at', order_type: 'desc' }
		end

		order_by = params[:filter][:order]

		@text_chunks = TextChunk.all
			.by_id(params[:id])
			.by_chunk_type(params[:chunk_type])
			.by_value(params[:value])
			.by_admin_user_id(params[:admin_user_id])
			.by_updated_by_id(params[:updated_by_id])
			.page(params[:page]).per(params[:limit])
			.order(order_by + ' ' + params[:filter][:order_type])
	end

	def new
		@text_chunk = TextChunk.new
    render :edit, locals: {text_chunk: @text_chunk}
	end

  def edit
    render :edit, locals: {text_chunk: @text_chunk}
  end

  def update
    text_chunk_params[:updated_by_id] = current_admin_user.id if current_admin_user.present?
    if @text_chunk.update_attributes(text_chunk_params)
      render :update, locals: {text_chunk: @text_chunk}
    else
      render :edit, locals: {text_chunk: @text_chunk}
    end
  end

	def create
		@text_chunk = TextChunk.new(text_chunk_params)
		@text_chunk.admin_user = current_admin_user if current_admin_user.present?
    if @text_chunk.save
      render :create, locals: {text_chunk: @text_chunk}
    else
      render :new, locals: {text_chunk: @text_chunk}
    end
	end

	def destroy
		@text_chunk.destroy
    render :destroy, locals: {text_chunk: @text_chunk}
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_text_chunk
			@text_chunk = TextChunk.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def text_chunk_params
			params.require(:text_chunk).permit!
		end
end
