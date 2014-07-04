class ApplicationController < ActionController::Base
  def login_required
    if session[:domain].present? && (session[:domain].nickname=="Admin" || session[:domain].nickname=="ContextIT")      
      return true
    end
    flash[:warning]='Please login to continue'
    session[:return_to]=request.url
    redirect_to "/admin/index.html"
    return false
  end

  def log_in! user
    session[:user_id] = user.id
    session[:domain] = user.domain    
    session[:style]  = DomainStyle.find_by_domain_id user.domain.id
  end

  def current_user
    User.find session[:user_id]
  end

  def get_first_application_id
    BrightTextApplication.where(:domain_id => session[:domain].id).order(:name).first.id.to_s
  end

  def find_application
    application = BrightTextApplication.find_by_id session[:br_application_id]
    application = BrightTextApplication.find_by_id get_first_application_id if application.blank?
    session[:br_application_id] = application.blank? ? nil : application.id
    application
  end

  def clone_stories(story_ids, story_set_id)
    story_ids.each do |id|
      story = Story.find(id).dup
      story.story_set_id = story_set_id
      story.story_authors.build().user_id = session[:user_id]
      story.save
    end
  end

  def clone_story_sets(story_set_ids, category_id)
    #debugger
    story_set_ids.each do |story_set_id|
      story_set_original = StorySet.find(story_set_id)
      story_set = story_set_original.dup
      story_set.category_id = category_id
      #debugger
      if story_set.save
        story_ids = story_set_original.stories.select(:id)
        clone_stories(story_ids, story_set.id)
      end
    end
  end

  def clone_categories(category_ids, application_id)
    category_ids.each do |category_id|
      category_original = StorySetCategory.find(category_id)
      category = category_original.dup
      category.application_id = application_id
      if category.save
        #debugger
        story_set_ids = category_original.story_sets.select(:id)
        clone_story_sets(story_set_ids, category.id)
      end
    end
  end
end
