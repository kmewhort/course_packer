class StaticPagesController < ApplicationController
  def home
    # if already signed in, redirect to the course packs index
    if user_signed_in?
      redirect_to course_packs_path
      return
    end

    respond_to do |format|
      format.html
    end
  end
end