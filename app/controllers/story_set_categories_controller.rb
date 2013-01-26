require 'rexml/document'

class StorySetCategoriesController < ApplicationController
  before_filter :find_filter, :only => [:index, :destroy]
  
  # GET /story_categories
  # GET /story_categories.xml
  def index
    if ( @filter.empty? != true && @filter != "__none" )
      if @filter == "__unassigned"
        application_id = nil
      else        
        application_id = @filter
        @application = BrightTextApplication.find(application_id)
      end
    end

    @story_set_categories = StorySetCategory.where({:domain_id => session[:domain].id}.merge(( @filter.empty? != true  && @filter != "__none")? {:application_id => application_id} : {})).order(( @filter.empty? != true && @filter != "__none" ) ? "rank" : nil)
    @applications = BrightTextApplication.where(:domain_id => session[:domain].id)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @story_set_categories }
    end
  end

  # GET /story_categories/1
  # GET /story_categories/1.xml
  def show
    @story_set_category = StorySetCategory.find(params[:id])
    raise ' not owner ' unless @story_set_category.domain_id == session[:domain].id
    respond_to do |format|
      format.html # show.html.erb
      format.xml  {
        render :xml => @story_set_category
      }
    end
  end

  # GET /story_categories/new
  # GET /story_categories/new.xml
  def new
    @story_set_category = StorySetCategory.new
    filter = params[:filter]
    if ( filter != nil && filter != "__unassigned" )
    @story_set_category.application_id = filter.to_i
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @story_set_category }
    end
  end

  # GET /story_categories/1/edit
  def edit
    @story_set_category = StorySetCategory.find(params[:id])
    raise ' not owner ' unless @story_set_category.domain_id == session[:domain].id
  end

  # POST /story_categories
  # POST /story_categories.xml
  def create
    @story_set_category = StorySetCategory.new(params[:story_set_category])
    @story_set_category.domain_id = session[:domain].id

    respond_to do |format|
      if @story_set_category.save
        format.html { redirect_to('/story_set_categories?filter=' + @story_set_category.application_id.to_s) }
        format.xml  { render :xml => @story_set_category, :status => :created, :location => @story_set_category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @story_set_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /story_categories/1
  # PUT /story_categories/1.xml
  def update
    @story_set_category = StorySetCategory.find(params[:id])
    raise ' not owner ' unless @story_set_category.domain_id == session[:domain].id
    respond_to do |format|
      if @story_set_category.update_attributes(params[:story_set_category])
        format.html { redirect_to('/story_set_categories?filter=' + @story_set_category.application_id.to_s) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @story_set_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /story_categories/1
  # DELETE /story_categories/1.xml
  def destroy
    @story_set_category = StorySetCategory.find(params[:id])
    # @filter = @story_set_category.application_id.to_s
    # if ( @filter == nil || @filter == "0")
      # @filter = ""
    # end
    #
    raise ' not owner ' unless @story_set_category.domain_id == session[:domain].id
    @story_set_category.destroy

    respond_to do |format|
      format.html { redirect_to('/story_set_categories?filter=' + @filter) }
      format.xml  { head :ok }
    end
  end

  def reorder_story_set_categories_rank
    if( params[:application_id].blank? )
      redirect_to story_set_categories_path
    elsif( params[:application_id] ==  "__unassigned")
      @story_set_categories = StorySetCategory.where("story_set_id IS NULL AND domain_id = ?", session[:domain].id).order(:rank)
    else
      @story_set_categories = StorySetCategory.where(:application_id => params[:application_id], :domain_id => session[:domain].id).order(:rank)
    end
  end

  def update_story_set_categories_rank
    #p params.to_yaml
    @story_set_categories = StorySetCategory.update(params[:story_set_categories].keys, params[:story_set_categories].values)
    redirect_to story_set_categories_path(:filter => params[:filter])
  end
  
  private
  def find_filter    
    # @filter = request[:filter]
    # @filter = "" if @filter == nil
    #
    if request[:filter] == "" || !request[:filter].blank?
      @filter = request[:filter]
    elsif session[:br_application_id] == "" || !session[:br_application_id].blank?
      @filter = session[:br_application_id]
    else
      @filter = BrightTextApplication.where(:domain_id => session[:domain].id).first.id.to_s
    end
    session[:br_application_id] = @filter
  end
  
end
