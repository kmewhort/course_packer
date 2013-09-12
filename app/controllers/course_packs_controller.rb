class CoursePacksController < ApplicationController
  before_filter :find_course_pack, only: [:edit, :update, :preview]
  before_filter :build_course_pack, only: [:create]
  before_filter :clean_params, only: [:update]

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

  def preview
    # if there have been no updates, use the cached version
    if @course_pack.preview_up_to_date?
      respond_to do |format|
        format.json { render json: { preview_file: @course_pack.preview.url } }
      end
      return
    end

    respond_to do |format|
      if @course_pack.generate_preview
        format.json { render json: { preview_file: @course_pack.preview.url } }
      else
        format.json { render json: @course_pack.error_messages, status: :unprocessable_entity }
      end
    end
  end

  private
  def find_course_pack
    @course_pack = CoursePack.find(params[:id])
  end

  def build_course_pack
    @course_pack = CoursePack.new
    @course_pack.contents.build({}, Article) #seed with an empty article
  end

  def clean_params
    # a concurrent request may have already destroyed an article, so clean out params for non-existent items
    if params[:course_pack] && params[:course_pack][:contents_attributes]
      existing_ids = @course_pack.contents.map{|cp| cp.id.to_s}
      params[:course_pack][:contents_attributes].delete_if do |k, v|
        !v['id'].nil? && !existing_ids.include?(v['id'])
      end
    end
    test = "test"
  end
end