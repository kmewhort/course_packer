class CoursePacksController < ApplicationController
  before_filter :find_course_pack, only: [:edit, :update, :destroy, :prepare_preview, :preview,
                                          :print_selection, :share_selection, :print, :show]
  before_filter :find_all_course_packs, only: [:index]
  before_filter :build_course_pack, only: [:new]
  before_filter :build_articles, only: [:update]
  authorize_resource
  helper LicenseHelper

  def new
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

  def destroy
    @course_pack.destroy

    respond_to do |format|
      format.html { redirect_to course_packs_path }
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

  def print_selection
    respond_to do |format|
      format.js
    end
  end

  def print
    pdf = @course_pack.print(params[:type].to_sym)
    self.response_body = File.read(pdf)
    self.content_type = 'application/pdf'
  end

  def share_selection
    respond_to do |format|
      format.js
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def index
    respond_to do |format|
      format.html
    end
  end

  private
  def find_course_pack
    @course_pack = CoursePack.find(params[:id])
  end

  def find_all_course_packs
    # TODO: users should also be able to view all public course packs
    @course_packs = CoursePack.where(owner_id: current_user.id)
  end

  def build_course_pack
    @course_pack = CoursePack.new

    if user_signed_in?
      @course_pack.owner = current_user
    else
      @course_pack.owner_session_token = session[:temp_user_id]
    end

    #seed with an empty article
    @course_pack.contents.build({}, Article)
    @course_pack.contents.last.build_license
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