class AppSubmissionsController < ApplicationController
  protect_from_forgery :except => [:submit]

  # GET /app_submissions
  # GET /app_submissions.xml
  def index
    @app_submissions = AppSubmission.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @app_submissions }
    end
  end

  # GET /app_submissions/1
  # GET /app_submissions/1.xml
  def show
    @app_submission = AppSubmission.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @app_submission }
    end
  end

  # GET /app_submissions/new
  # GET /app_submissions/new.xml
  def new
    @app_submission = AppSubmission.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @app_submission }
    end
  end

  # GET /app_submissions/1/edit
  def edit
    @app_submission = AppSubmission.find(params[:id])
  end

  # POST /app_submissions
  # POST /app_submissions.xml
  def create
    @app_submission = AppSubmission.new(params[:app_submission])

    respond_to do |format|
      if @app_submission.save
        format.html { redirect_to(@app_submission, :notice => 'App submission was successfully created.') }
        format.xml  { render :xml => @app_submission, :status => :created, :location => @app_submission }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @app_submission.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /app_submissions/1
  # PUT /app_submissions/1.xml
  def update
    @app_submission = AppSubmission.find(params[:id])

    respond_to do |format|
      if @app_submission.update_attributes(params[:app_submission])
        format.html { redirect_to(@app_submission, :notice => 'App submission was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @app_submission.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /app_submissions/1
  # DELETE /app_submissions/1.xml
  def destroy
    @app_submission = AppSubmission.find(params[:id])
    @app_submission.destroy

    respond_to do |format|
      format.html { redirect_to(app_submissions_url) }
      format.xml  { head :ok }
    end
  end
  
  def submit
    @app_data = request.raw_post
    logger.info " DATA FROM APP: " + @app_data
    
    doc = REXML::Document.new( @app_data )
    app_id = doc.root.attributes["id"]
    
    logger.info "HAVE APP ID " + app_id.to_s
    
    app = BrightTextApplication.find app_id
    
    logger.info "HAVE APP " + app.to_s
    
    
    
    @app_submission = AppSubmission.new( {:bright_text_application_id => app.id, :domain_id => app.domain_id } )
    @app_submission.descriptor = @app_data
    
    values = []
    digests = []
    questions = []
    
    doc.root.each_element( "//StorySet" ) do | storySet |  
      storySetId  = storySet.attributes["id"].to_i
      sliderValue = storySet.attributes["toneValue"].to_i
      sliderRange = storySet.attributes["toneRange"].to_i
      digest = storySet.get_elements("Digest")[0].text
      
      values << { :id => storySetId, :value => sliderValue, :range => sliderRange }
      digests << { :id => storySetId, :digest => digest }
      questions << StorySet.find( storySetId ).name 
      
    end 
    
    companyEl = doc.root.get_elements("//SurveyResultMeta/Company");
    submissionMeta = { :company => companyEl[0].text }
    
    @app_submission.story_set_values    = values .to_json
    @app_submission.story_set_digests   = digests.to_json
    @app_submission.submission_metadata = submissionMeta.to_json
    
    @app_submission.save
    
    
    
    SurveyMailer.survey_result_email( questions, values, digests, submissionMeta ).deliver
    
    render :js => { :submission_id => @app_submission.id }.to_json
    headers['content-type']='text/javascript';    
  end
end
