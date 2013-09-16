class CoursePacksController < ApplicationController
  before_filter :find_course_pack, only: [:edit, :update, :prepare_preview, :preview]
  before_filter :build_course_pack, only: [:create]
  before_filter :build_articles, only: [:update]

  def create
    @course_pack.save #save immediately to allow in-place editing

    respond_to do |format|
      format.html { redirect_to edit_course_pack_path(@course_pack) }
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    # content may have been deleted in the course of an upload/processing, so clean parameters
    # of non-existent content before saving
    clean_params

    respond_to do |format|
      if @course_pack.update_attributes(params[:course_pack])
        format.html { render action: "edit", notice: 'Successfully updated.' }
        format.json { render json: @course_pack }
      else
        format.html { render action: "edit" }
        format.json { render json: @course_pack.error_messages, status: :unprocessable_entity }
      end
    end
  end

  def prepare_preview
    # if there have been no updates, no need to re-generate
    if @course_pack.preview_up_to_date?
      respond_to do |format|
        format.json { head :no_content }
      end
      return
    end

    respond_to do |format|
      if @course_pack.generate_preview
        format.json { head :no_content }
      else
        format.json { render json: @course_pack.error_messages, status: :unprocessable_entity }
      end
    end
  end

  def preview
    self.response_body = File.read(@course_pack.preview.path)
    self.content_type = 'application/pdf'
  end

  private
  def find_course_pack
    @course_pack = CoursePack.find(params[:id])
  end

  def build_course_pack
    @course_pack = CoursePack.new
    @course_pack.contents.build({}, Article) #seed with an empty article
  end

  def build_articles
    # create new articles
    if params[:course_pack] && params[:course_pack][:contents_attributes]
      existing_ids = @course_pack.contents.map{|cp| cp.id.to_s}
      params[:course_pack][:contents_attributes].each do |k, v|
        @course_pack.contents.build({_id: v['_id'], _type: v['_type']}).save if !existing_ids.include?(v['id'])
      end
    end
  end

  def clean_params
    # a concurrent request may have already destroyed an article, so clean out params for non-existent items
    if params[:course_pack] && params[:course_pack][:contents_attributes]
      existing_ids = @course_pack.contents.map{|cp| cp.id.to_s}
      params[:course_pack][:contents_attributes].delete_if do |k, v|
        !v['id'].nil? && !existing_ids.include?(v['id'])
      end
    end
  end
end