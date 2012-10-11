class StoriesController < ApplicationController
  # GET /stories
  # GET /stories.xml
  def index
    @filter = request[:filter]
    @filter = "" if @filter == nil  
    
    queryAndParts = ["domain_id = ?"]
    queryParams   = [session[:domain].id ]
    
    if ( @filter.empty? != true  && @filter != "__none")
      if @filter == "__unassigned"
        queryAndParts << "story_set_id IS NULL"
      else 
        queryAndParts << "story_set_id = ?"
        queryParams   << @filter
      end
    end
    
    @stories = Story.find_by_sql ["select * from stories where " + queryAndParts.join(" AND "), queryParams].flatten
    @story_sets = StorySet.find_by_sql ["select * from story_sets where domain_id = ?", session[:domain].id ]
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @stories }
    end
  end

  # GET /stories/1
  # GET /stories/1.xml
  def show
    @story = Story.find(params[:id])
    raise ' not owner ' unless @story.domain_id == session[:domain].id
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @story }
      format.js   { render :js => request[:callback] + "(" + @story.descriptor + ")" }
    end
  end

  # GET /stories/new
  # GET /stories/new.xml
  def new
    @story = Story.new
    filter = params[:filter]
    if ( filter != nil && filter != "__unassigned" )
      @story.story_set_id = filter.to_i
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @story }
    end
  end
  
  # GET /stories/XX/clone
  def clone
    @sourceStory = Story.find(params[:id])    
    @story = Story.new( {:name => @sourceStory.name + " Clone", :descriptor => @sourceStory.descriptor, :story_set_id => @sourceStory.story_set_id, :domain_id => session[:domain].id } )
    respond_to do |format|
        format.html { render :action => "new" }
    end
  end  

  # GET /stories/1/edit
  def edit
    @story = Story.find(params[:id])
    raise ' not owner ' unless @story.domain_id == session[:domain].id
  end

  # POST /stories
  # POST /stories.xml
  def create
    @story = Story.new(params[:story])
    @story.domain_id = session[:domain].id
    
    respond_to do |format|
      if @story.save
        format.html { redirect_to("/stories?filter=" + @story.story_set_id.to_s, :notice => 'Story was successfully created.') }
        format.xml  { render :xml => @story, :status => :created, :location => @story }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @story.errors, :status => :unprocessable_entity }
      end
    end
    
    
  end

  # PUT /stories/1
  # PUT /stories/1.xml
  def update
    @story = Story.find(params[:id])
    raise ' not owner ' unless @story.domain_id == session[:domain].id
    respond_to do |format|
      if @story.update_attributes(params[:story])
        format.html { redirect_to("/stories?filter=" + @story.story_set_id.to_s, :notice => 'Story was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @story.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /stories/1
  # DELETE /stories/1.xml
  def destroy
    @story = Story.find(params[:id])
    raise ' not owner ' unless @story.domain_id == session[:domain].id
    @story.destroy

    respond_to do |format|
      format.html { redirect_to("/stories?filter=" + @story.story_set_id.to_s) }
      format.xml  { head :ok }
    end
  end
  
  def legacyxml
    @story = Story.find(params[:id])
    
    #invoke the save proxy to get xml
    result = REXML::Document.new("<Story/>")      
    result.root.attributes["id"]   = @story.id
    result.root.attributes["name"] = @story.name
    @story.toXml( result.root )
    
    #return the xml
    render :xml => result 
  end
  
  def clonesxml
    @story = Story.find(params[:id])
    setid = @story.story_set_id
    
    result = REXML::Document.new("<RelatedStories/>")
    if ( setid )
      stories = Story.find_by_sql [ "select id from stories where story_set_id = ? and id <> ?", setid, @story.id ];
      stories.each do | story |
        storiesEl = result.root.add_element("StoryId")
        storiesEl.text = story.id.to_s
      end
    end
    render :xml => result 
  end
end
