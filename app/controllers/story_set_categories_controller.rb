require 'rexml/document'

class StorySetCategoriesController < ApplicationController
  # GET /story_categories
  # GET /story_categories.xml
  def index
    @filter = request[:filter]
    @filter = "" if @filter == nil  
    
    queryAndParts = ["domain_id = ?"]
    queryParams   = [session[:domain].id ]
    
    if ( @filter.empty? != true && @filter != "__none" )
      if @filter == "__unassigned"
        queryAndParts << "application_id IS NULL"
      else 
        queryAndParts << "application_id = ?"
        queryParams   << @filter
      end
    end  
  
    @story_set_categories = StorySetCategory.find_by_sql [ "select * from story_set_categories where " + queryAndParts.join(" AND "), queryParams].flatten
    @applications = BrightTextApplication.find_by_sql [ "select * from bright_text_applications where domain_id = ?", session[:domain].id ]
    
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
        format.html { redirect_to(story_set_categories_url) }
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
        format.html { redirect_to(story_set_categories_url) }
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
    @story_set_category = StoryCategory.find(params[:id])
    raise ' not owner ' unless @story_set_category.domain_id == session[:domain].id
    @story_set_category.destroy

    respond_to do |format|
      format.html { redirect_to(story_set_categories_url) }
      format.xml  { head :ok }
    end
  end
end
