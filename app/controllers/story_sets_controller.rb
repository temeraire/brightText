class StorySetsController < ApplicationController
  # GET /story_sets
  # GET /story_sets.xml
  def index
    @filter = request[:filter]
    @filter = "" if @filter == nil  
    
    queryAndParts = ["domain_id = ?"]
    queryParams   = [session[:domain].id ]
    
    if ( @filter.empty? != true  && @filter != "__none")
      if @filter == "__unassigned"
        queryAndParts << "category_id IS NULL"
      else 
        queryAndParts << "category_id = ?"
        queryParams   << @filter
      end
    end
  
    @story_sets = StorySet.find_by_sql ["select * from story_sets where " + queryAndParts.join(" AND "), queryParams].flatten
    @categories = StorySetCategory.find_by_sql [ "select * from story_set_categories where domain_id = ?", session[:domain].id ]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @story_sets }
    end
  end

  # GET /story_sets/1
  # GET /story_sets/1.xml
  def show
    @story_set = StorySet.find(params[:id])
    raise ' not owner ' unless @story_set.domain_id == session[:domain].id
    respond_to do |format|
      format.html # show.html.erb
      format.xml  {
        result = REXML::Document.new("<StorySet/>")
        stories = result.root.add_element("Stories")
        storyEntries = Story.find_by_sql ["select * from stories where story_set_id = ?", @story_set.id ]
        storyEntries.each do | storyEntry |
          story = stories.add_element("Story")      
          story.attributes["id"] = storyEntry.id
        end
      
        render :xml => result 
      }
    end
  end

  # GET /story_sets/new
  # GET /story_sets/new.xml
  def new
    @story_set = StorySet.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @story_set }
    end
  end

  # GET /story_sets/1/edit
  def edit
    @story_set = StorySet.find(params[:id])
    raise ' not owner ' unless @story_set.domain_id == session[:domain].id
  end

  # POST /story_sets
  # POST /story_sets.xml
  def create
    @story_set = StorySet.new(params[:story_set])
    @story_set.domain_id = session[:domain].id
    respond_to do |format|
      if @story_set.save
        format.html { redirect_to(story_sets_url) }
        format.xml  { render :xml => @story_set, :status => :created, :location => @story_set }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @story_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /story_sets/1
  # PUT /story_sets/1.xml
  def update
    @story_set = StorySet.find(params[:id])
    raise ' not owner ' unless @story_set.domain_id == session[:domain].id
    respond_to do |format|
      if @story_set.update_attributes(params[:story_set])
        format.html { redirect_to(story_sets_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @story_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /story_sets/1
  # DELETE /story_sets/1.xml
  def destroy
    @story_set = StorySet.find(params[:id])
    raise ' not owner ' unless @story_set.domain_id == session[:domain].id
    @story_set.destroy

    respond_to do |format|
      format.html { redirect_to(story_sets_url) }
      format.xml  { head :ok }
    end
  end
end
