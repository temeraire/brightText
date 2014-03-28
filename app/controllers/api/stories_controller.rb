class Api::StoriesController < ApplicationController

  # GET /stories
  # GET /stories.xml
  def index
    @user_name = params[:user_name]
    @password = request[:password]
    @application_id = request[:application_id]

    if (@user = User.authenticate @user_name, @password)
      @stories = Story.where("(user_id IS NULL OR user_id = ?) AND (bright_text_application_id = ? OR bright_text_application_id is NULL)",@user.id, @application_id).order(:name)
    else

    end

    respond_to do |format|
      format.json {render :json=> { :success => "true", :stories => @stories } }
      format.xml  { render :xml => @stories }
    end
  end
end
