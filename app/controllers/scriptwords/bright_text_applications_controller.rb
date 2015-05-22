class Scriptwords::BrightTextApplicationsController < ScriptwordsController
  protect_from_forgery :except => [:index]
  before_filter :login_required
  # GET /applications
  # GET /applications.xml
  def index
    @bt_applications = BrightTextApplication.find_by_sql [ "select * from bright_text_applications where domain_id = ?", session[:domain].id ]

    respond_to do |format|
      format.html { render :index}
      format.xml  { render :xml => @bt_applications }
    end
  end

  # GET /applications/1
  # GET /applications/1.xml
  def show
    @bt_application = BrightTextApplication.find(params[:id])
    respond_to do |format|
      format.html {
        raise ' not owner ' unless @bt_applications.domain_id == session[:domain].id

      }
      format.xml  {
=begin
<Application id="12">
 <StorySetCategories>
   <StorySetCategory id="15" name="safsdf"><!-- Survey -->
     <StorySets>
       <StorySet id="32" name="asdfasdf"><!-- Question -->
         <Stories>
           <Story id="1140" name="afdaf"><!-- Recombinant Answer 1 --></Story>
           <Story id="1143" name="bb"><!-- Recombinant Answer 2 --></Story>
           <Story id="1137" name="ddaa"><!-- Recombinant Answer 3 --></Story>
         </Stories>
       </StorySet>
     </StorySets>
   </StorySetCategory>
 </StorySetCategories>
</Application>
=end

        result = REXML::Document.new("<Application/>")
        result.root.attributes["id"] = @bt_application.id.to_s
        categoriesEl = result.root.add_element("StorySetCategories")
        categoryObjects = StorySetCategory.find_by_sql ["select * from story_set_categories where application_id = ? order by rank asc", @bt_application.id ]
        categoryObjects.each do | category |
          categoryEl = categoriesEl.add_element("StoryCategory")
          categoryEl.attributes["id"]   = category.id
          categoryEl.attributes["name"] = category.name
          storySetsEl = categoryEl.add_element("StorySets");
          storySetObjects = StorySet.find_by_sql [ "select * from story_sets where category_id = ? order by rank asc", category.id ]
          storySetObjects.each do | storySet |
            storySetEl = storySetsEl.add_element("StorySet");
            storySetEl.attributes["id"]   = storySet.id
            storySetEl.attributes["name"] = storySet.name
            storiesEl = storySetEl.add_element("Stories")
            storyEntries = Story.find_by_sql ["select * from stories where story_set_id = ? order by rank", storySet.id ]
            storyEntries.each do | storyEntry |
              storyEl = storiesEl.add_element("Story")
              storyEl.attributes["id"]   = storyEntry.id
              storyEl.attributes["name"] = storyEntry.name
              storyEntry.toXml( storyEl )
              # puke out the xml-ified story data
            end
          end
        end
        render :xml => result

      }
    end
  end

  def result
    appid = params[:id]

    submissions = AppSubmission.find_by_sql( ["select * from app_submissions where bright_text_application_id = ?", appid ] )

    stories = []
    result  = { :app => appid, :submissions => stories }

    submissions.each do | submission |

      answers = []

      meta = { :company => "" } # default for older apps

      values  = JSON.parse( submission.story_set_values )
      digests = JSON.parse( submission.story_set_digests )
      meta    = JSON.parse( submission.submission_metadata ) unless submission.submission_metadata == nil

      story = { :created => submission.created_at.to_s, :company => meta["company"], :answers => answers }

      values.each_with_index do | value, index |
        digest = digests[ index ]
        value[:digest] = digest["digest"]
        answers << value
      end

      stories << story

    end

    logger.info " request format " + request.format.to_s
    case request.format.to_s
    when 'text/csv'
      rows = []
      stories.each do | story |
        cols = []
        cols << story[:created]
        cols << story[:company]
        story[:answers].each do | answer |
          cols << answer["value"]
        end
        rows << cols.join(",")
      end
      send_data rows.join("\n")
      headers['content-type']='text/comma-separated-values'

    when 'text/javascript'
      render :js => result.to_json
      headers['content-type']='text/javascript'
    end
  end

  # GET /applications/new
  # GET /applications/new.xml
  def new
    @bt_application = BrightTextApplication.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @bt_application }
    end
  end

  # GET /applications/1/edit
  def edit
    @bt_application = BrightTextApplication.find(params[:id])
    raise ' not owner ' unless @bt_application.domain_id == session[:domain].id
  end

  # POST /applications
  # POST /applications.xml
  def create
    @bt_application = BrightTextApplication.new(params[:bright_text_application])
    @bt_application.domain_id = session[:domain].id
    respond_to do |format|
      if @bt_application.save
        clone_categories(params[:category_ids], @bt_application.id) unless params[:category_ids].blank?
        format.html { redirect_to(bright_text_applications_url) }
        format.xml  { render :xml => @bt_application, :status => :created, :location => @bt_application }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @bt_application.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /applications/1
  # PUT /applications/1.xml
  def update
    @bt_application = BrightTextApplication.find(params[:id])
    raise ' not owner ' unless @bt_application.domain_id == session[:domain].id
    respond_to do |format|
      if @bt_application.update_attributes(params[:bright_text_application])
        format.html { redirect_to(wordslider_bright_text_applications_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @bt_application.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /applications/1
  # DELETE /applications/1.xml
  def destroy
    @bt_application = BrightTextApplication.find(params[:id])
    raise ' not owner ' unless @bt_application.domain_id == session[:domain].id
    @bt_application.destroy

    respond_to do |format|
      format.html { redirect_to(wordslider_bright_text_applications_url) }
      format.xml  { head :ok }
    end
  end

  def clone
    @bt_application_original = BrightTextApplication.find(params[:id])
    @bt_application = @bt_application_original.dup
    number_of_similar_name_applications = BrightTextApplication.count(:conditions => ["name like ?", @bt_application_original.name + "%"])
    @bt_application.name = @bt_application.name + "-" + (number_of_similar_name_applications + 1).to_s
    @categories = @bt_application_original.story_set_categories(:include => :stories)
    #debugger
    respond_to do |format|
      format.html { render :action => "new" }
    end
  end
end
