class WatchingVideoCategoriesController < ApplicationController
  before_action :set_watching_video_category, only: [:show, :edit, :update, :destroy]

  # GET /watching_video_categories
  # GET /watching_video_categories.json
  def index
    @watching_video_categories = WatchingVideoCategory.order(name: :asc)
  end

  # GET /watching_video_categories/1
  # GET /watching_video_categories/1.json
  def show
  end

  # GET /watching_video_categories/new
  def new
    @watching_video_category = WatchingVideoCategory.new
  end

  # GET /watching_video_categories/1/edit
  def edit
  end

  # POST /watching_video_categories
  # POST /watching_video_categories.json
  def create
    @watching_video_category = WatchingVideoCategory.new(watching_video_category_params)

    respond_to do |format|
      if @watching_video_category.save
        format.html { redirect_to watching_video_categories_path, notice: 'Watching video category was successfully created.' }
        format.json { render action: 'show', status: :created, location: @watching_video_category }
      else
        format.html { render action: 'new' }
        format.json { render json: @watching_video_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /watching_video_categories/1
  # PATCH/PUT /watching_video_categories/1.json
  def update
    respond_to do |format|
      if @watching_video_category.update(watching_video_category_params)
        format.html { redirect_to watching_video_categories_path, notice: 'Watching video category was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @watching_video_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /watching_video_categories/1
  # DELETE /watching_video_categories/1.json
  def destroy
    @watching_video_category.destroy
    respond_to do |format|
      format.html { redirect_to watching_video_categories_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_watching_video_category
      @watching_video_category = WatchingVideoCategory.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def watching_video_category_params
      params.require(:watching_video_category).permit!
    end
end
