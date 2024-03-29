require 'rexml/document'

class Admin::StorySetCategoriesController < ApplicationController
  protect_from_forgery :except => [:index]
  before_filter :login_required
  # GET /story_categories
  # GET /story_categories.xml
  def index
    @filter  = request[:filter]
    @page = params[:page]
    @applications = BrightTextApplication.where(:domain_id => session[:domain].id).order(:name)
    if !(@filter == "__none" || @filter == "__unassigned")
      @application = @applications.find_by_id @filter
      @application = @applications.find_by_id session[:br_application_id] if @application.blank?
      @application = @applications.first if @application.blank?
      session[:br_application_id] = @application.id unless @application.blank?
    end

    if @filter == "__unassigned"
      @story_set_categories = StorySetCategory.where("domain_id = ? AND application_id is NULL", session[:domain].id).order(:name)
    else
      @story_set_categories = StorySetCategory.where({:domain_id => session[:domain].id}.merge(
                              (@filter == "__none")? {} : {:application_id => @application})).order(:name)
    end

    @filter = @application.id.to_s if @filter.blank? && !@application.blank? #update @filter for selection list and breadcrumbs similar values
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @story_set_categories }
    end
  end

  # GET /story_categories/1
  # GET /story_categories/1.xml
  def show
    @category = StorySetCategory.find(params[:id])
        
    raise ' not owner ' unless @category.domain_id == session[:domain].id
    respond_to do |format|
      format.html # show.html.erb
      format.xml  {
        render :xml => @category
      }
    end
  end

  # GET /story_categories/new
  # GET /story_categories/new.xml
  def new
    @story_set_category = StorySetCategory.new
    filter = params[:filter]
    if ( filter != nil && filter != "__unassigned" )
      @application = BrightTextApplication.find_by_id filter
      @story_set_category.application_id = @application.id if @application.present?
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @story_set_category }
    end
  end

  # GET /story_categories/1/edit
  def edit
    @story_set_category = StorySetCategory.find(params[:id])
    @page = params[:page]
    session[:page]=@page
    raise ' not owner ' unless @story_set_category.domain_id == session[:domain].id
  end

  # POST /story_categories
  # POST /story_categories.xml
  def create
    @story_set_category = StorySetCategory.new(params[:story_set_category])
    @story_set_category.domain_id = session[:domain].id
    @story_set_category.user_id = session[:user_id]
    
    respond_to do |format|
      if @story_set_category.save
        clone_story_sets(params[:story_sets], @story_set_category.id) unless params[:story_sets].blank?
        format.html { redirect_to('/admin/story_set_categories?filter=' + @story_set_category.application_id.to_s + "&page=" + session[:page].to_s, :notice => session[:style].group_alias.titleize + ' was successfully created.') }
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
        format.html { redirect_to('/admin/story_set_categories?filter=' + @story_set_category.application_id.to_s + '&page=' + session[:page], :notice => session[:style].group_alias.titleize + ' was successfully updated.') }
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
    @page = params[:page]
    @story_set_category = StorySetCategory.find(params[:id])
    # @filter = @story_set_category.application_id.to_s
    # if ( @filter == nil || @filter == "0")
    # @filter = ""
    # end

    raise ' not owner ' unless @story_set_category.domain_id == session[:domain].id
    @story_set_category.destroy

    respond_to do |format|
      format.html { redirect_to admin_story_set_categories_path(:filter => @story_set_category.application_id.to_s,  :page => @page) }
      format.xml  { head :ok }
    end
  end

  def reorder_story_set_categories_rank
    if( params[:application_id].blank? )
      redirect_to admin_story_set_categories_path
    elsif( params[:application_id] ==  "__unassigned")
      @story_set_categories = StorySetCategory.where("story_set_id IS NULL AND domain_id = ?", session[:domain].id).order(:rank)
    else
      @story_set_categories = StorySetCategory.where(:application_id => params[:application_id], :domain_id => session[:domain].id).order(:rank)
    end
  end

  def update_story_set_categories_rank
    #p params.to_yaml
    @story_set_categories = StorySetCategory.update(params[:story_set_categories].keys, params[:story_set_categories].values)
    redirect_to admin_story_set_categories_path(:filter => params[:filter])
  end

  def clone
    @page = params[:page]
    session[:page]=@page
    @story_set_category_original = StorySetCategory.find(params[:id])
    @story_set_category = @story_set_category_original.dup
    number_of_similar_named_storyset_categories = StorySetCategory.where("name like ? AND application_id = ?", @story_set_category_original.name + "%", @story_set_category_original.application_id).count('id')
    @story_set_category.name = @story_set_category.name.partition("-")[0] + "-" + (number_of_similar_named_storyset_categories + 1).to_s
    @story_sets = @story_set_category_original.story_sets(:include => :stories)
    #debugger
    respond_to do |format|
      format.html { render :action => "new" }
    end
  end
  
    
  def category_story_sets
    if params[:id].present?
      @story_sets = StorySet.where(:category_id => params[:id])
    else
      @story_sets = []
    end

    respond_to do |format|
      format.json { render :json => @story_sets }
    end
  end
end
