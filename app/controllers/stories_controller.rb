class StoriesController < ApplicationController
  # GET /stories
  # GET /stories.xml
  def index
    @filter = request[:filter]
    @filter = "" if @filter == nil
     @highlighted_phreses = params[:q]
    
    if ( @filter.empty? != true  && @filter != "__none")
      if @filter == "__unassigned"
        story_set_id = nil
      else 
        story_set_id   = @filter
      end
    end
    
    if(params[:q].blank?)
      @stories = Story.where(
        {:domain_id => session[:domain].id}.merge(
          ( @filter.empty? != true  && @filter != "__none")? {:story_set_id => story_set_id} : {}
        )
      ).order(( @filter.empty? != true  && @filter != "__none")? "rank" : nil)
      
    else
      @stories = Story.search_for(params[:q])
      @highlighted_phreses = params[:q].split()
    end
    
    @story_sets = StorySet.where(:domain_id => session[:domain].id)
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
    @story.rank = 1 + Story.maximum(:rank, :conditions => ["story_set_id = ?", @story.story_set_id])
    @story.domain_id = session[:domain].id
    
    respond_to do |format|
      if @story.save
        format.json{ render :json=> {:success => "true"} }
        format.html { redirect_to("/stories?filter=" + @story.story_set_id.to_s, :notice => 'Story was successfully created.') }
        format.xml  { render :xml => @story, :status => :created, :location => @story }
      else
        format.json{ render :json=> {:success => "false"} }
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
        format.json{ render :json=> {:success => "true"} }
        format.html { redirect_to("/stories?filter=" + @story.story_set_id.to_s, :notice => 'Story was successfully updated.') }
        format.xml  { head :ok }
      else
        format.json{ render :json=> {:success => "false"} }
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
  
  def reorder_stories_rank
    if( params[:story_set_id].blank? )
      redirect_to stories_path     
    elsif( params[:story_set_id] ==  "__unassigned")
      @stories = Story.where("story_set_id IS NULL AND domain_id = ?", session[:domain].id).order(:rank)
    else
      @stories = Story.where(:story_set_id => params[:story_set_id], :domain_id => session[:domain].id).order(:rank)
    end
  end
  
  def update_stories_rank
    #p params.to_yaml
    @stories = Story.update(params[:stories].keys, params[:stories].values)    
    redirect_to stories_path(:filter => params[:filter])
  end
end
