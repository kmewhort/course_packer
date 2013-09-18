# The LicensesController controls the form fields appropriate wrt already-filled in license values; all
# updates to licenses are handled through nested attributes in Articles
class LicensesController < ApplicationController
  before_filter :build_license

  def edit
    # index in the client-side list
    @article_index = params[:article_index]

    respond_to do |format|
      format.js
    end
  end

  private
  def build_license
    @license = License.new(params[:license])
    @license.update_defaults
  end
end