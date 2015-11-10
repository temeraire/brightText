require 'rexml/document'

class Api::ApologiesController < ActionController::Base
    after_filter{
      puts response.body
    } 
  def get_user_stories
    @user_name = params[:user_name]
    @password = request[:password]
    @bt_application = BrightTextApplication.where(:name=>"ApologyWiz").first #request[:application_id]    

    if (@user = User.authenticate_user @user_name, @password, @bt_application.id)
      @stories = Story.where("(user_id IS NULL OR user_id = ?) AND (bright_text_application_id = ? OR bright_text_application_id is NULL)",@user.id, @bt_application.id).order(:name)
    else

    end

    respond_to do |format|
      format.json {render :json=> { :success => "true", :stories => @stories } }
      format.xml  { render :xml => @stories }
    end
  end

  def get_user_application_stories
    @user_name = params[:user_name]
    @password = request[:password]
    @bt_application = BrightTextApplication.where(:name=>"ApologyWiz").first #request[:application_id]

    if (!(@user = User.authenticate_user @user_name, @password, @bt_application.id))
      
      @user = User.find_by_email(@user_name);
      if(@user.blank?)
        @user = User.new
        @user.email = @user_name;
        @user.password = @password
        @user.domain_id = @bt_application.domain_id
        @user.customer!
        @user.group = Group.new
        @user.group.name = "Apologies"

        if @user.save
          GroupMember.where(:email => @user.email).update_all(:user_id=>@user.id)
        end
      end
    end

    respond_to do |format|
      format.xml  {

        #<Application id="12">
        # <StorySetCategories>
        #   <StorySetCategory id="15" name="safsdf"><!-- Survey -->
        #     <StorySets>
        #       <StorySet id="32" name="asdfasdf"><!-- Question -->
        #         <Stories>
        #           <Story id="1140" name="afdaf"><!-- Recombinant Answer 1 --></Story>
        #           <Story id="1143" name="bb"><!-- Recombinant Answer 2 --></Story>
        #           <Story id="1137" name="ddaa"><!-- Recombinant Answer 3 --></Story>
        #         </Stories>
        #       </StorySet>
        #     </StorySets>
        #   </StorySetCategory>
        # </StorySetCategories>
        #</Application>

        result = REXML::Document.new("<Application/>")
        if(@bt_application.present?)
          result.root.attributes["id"] = @bt_application.id.to_s
          categoriesEl = result.root.add_element("StorySetCategories")
          @categories_sql =
            "SELECT DISTINCT story_set_categories.* FROM story_set_categories " +
            "INNER JOIN story_sets ON story_set_categories.id = story_sets.category_id " +
            "INNER JOIN stories ON story_sets.id= stories.story_set_id " +
            "WHERE story_set_categories.application_id = ? " +
            "AND (stories.user_id = ? " +
            "OR stories.user_id IN (SELECT groups.user_id FROM groups INNER JOIN group_members ON groups.id = group_members.group_id " +
            "WHERE group_members.email = ? AND group_members.bright_text_application_id = ?) " +
            "OR stories.public = TRUE) " +
            "ORDER BY  story_set_categories.rank";
          categoryObjects = StorySetCategory.find_by_sql [@categories_sql, @bt_application.id, @user.id, @user.email, @bt_application.id ]

          categoryObjects.each do | category |
            categoryEl = categoriesEl.add_element("StoryCategory")
            categoryEl.attributes["id"]   = category.id
            categoryEl.attributes["name"] = category.name
            storySetsEl = categoryEl.add_element("StorySets");

            @story_set_sql =
              "SELECT DISTINCT story_sets.* FROM story_sets " +
              "INNER JOIN stories ON story_sets.id= stories.story_set_id " +
              "WHERE  story_sets.category_id = ? AND stories.bright_text_application_id = ? " +
              "AND (stories.user_id = ? " +
              "OR stories.user_id IN (SELECT groups.user_id FROM groups INNER JOIN group_members ON groups.id = group_members.group_id " +
              "WHERE group_members.email = ? AND group_members.bright_text_application_id = ?) " +
              "OR stories.public = TRUE) " +
              "ORDER BY  story_sets.rank";
            storySetObjects = StorySet.find_by_sql [ @story_set_sql, category.id, @bt_application.id, @user.id, @user.email, @bt_application.id ]
            storySetObjects.each do | storySet |
              storySetEl = storySetsEl.add_element("StorySet");
              storySetEl.attributes["id"]   = storySet.id
              storySetEl.attributes["name"] = storySet.name
              storiesEl = storySetEl.add_element("Stories")
              @stories_sql =
                "SELECT DISTINCT stories.* FROM stories " +
                "WHERE stories.story_set_id = ? AND stories.bright_text_application_id = ? " +
                "AND (stories.user_id = ? " +
                "OR stories.user_id IN (SELECT groups.user_id FROM groups INNER JOIN group_members ON groups.id = group_members.group_id " +
                "WHERE group_members.email = ? AND group_members.bright_text_application_id = ?) " +
                "OR stories.public = TRUE) " +
                "ORDER BY  stories.rank";
              storyEntries = Story.find_by_sql [@stories_sql, storySet.id, @bt_application.id, @user.id, @user.email, @bt_application.id ]
              storyEntries.each do | storyEntry |
                storyEl = storiesEl.add_element("Story")
                storyEl.attributes["id"]   = storyEntry.id
                storyEl.attributes["name"] = storyEntry.name                
                storyEl.attributes["scope"] = storyEntry.public? ? "0" : "1";
                storyEntry.toXml( storyEl )
                # puke out the xml-ified story data
              end
            end
          end
        end
        render :xml => result
      }
    end
  end
  
    
    
  def get_user_private_stories
    @user_name = params[:user_name]
    @password = request[:password]
    @bt_application = BrightTextApplication.where(:name=>"ApologyWiz").first #request[:application_id]

    if (!(@user = User.authenticate_user @user_name, @password,@bt_application.id))
      
      @user = User.find_by_email(@user_name);
      if(@user.blank?)
        @user = User.new
        @user.email = @user_name;
        @user.password = @password
        @user.domain_id = @bt_application.domain_id
        @user.customer!
        @user.group = Group.new
        @user.group.name = "Apologies"

        if @user.save
          GroupMember.where(:email => @user.email).update_all(:user_id=>@user.id)
        end
      end
    end

    respond_to do |format|
      format.xml  {

        #<Application id="12">
        # <StorySetCategories>
        #   <StorySetCategory id="15" name="safsdf"><!-- Survey -->
        #     <StorySets>
        #       <StorySet id="32" name="asdfasdf"><!-- Question -->
        #         <Stories>
        #           <Story id="1140" name="afdaf"><!-- Recombinant Answer 1 --></Story>
        #           <Story id="1143" name="bb"><!-- Recombinant Answer 2 --></Story>
        #           <Story id="1137" name="ddaa"><!-- Recombinant Answer 3 --></Story>
        #         </Stories>
        #       </StorySet>
        #     </StorySets>
        #   </StorySetCategory>
        # </StorySetCategories>
        #</Application>

        result = REXML::Document.new("<Application/>")
        if(@bt_application.present?)
          result.root.attributes["id"] = @bt_application.id.to_s
          categoriesEl = result.root.add_element("StorySetCategories")
          @categories_sql =
            "SELECT DISTINCT story_set_categories.* FROM story_set_categories " +
            "INNER JOIN story_sets ON story_set_categories.id = story_sets.category_id " +
            "INNER JOIN stories ON story_sets.id= stories.story_set_id " +
            "WHERE story_set_categories.application_id = ? " +
            "AND stories.user_id = ? " +         
            "ORDER BY  story_set_categories.rank";
          categoryObjects = StorySetCategory.find_by_sql [@categories_sql, @bt_application.id, @user.id ]

          categoryObjects.each do | category |
            categoryEl = categoriesEl.add_element("StoryCategory")
            categoryEl.attributes["id"]   = category.id
            categoryEl.attributes["name"] = category.name
            storySetsEl = categoryEl.add_element("StorySets");

            @story_set_sql =
              "SELECT DISTINCT story_sets.* FROM story_sets " +
              "INNER JOIN stories ON story_sets.id= stories.story_set_id " +
              "WHERE  story_sets.category_id = ? AND stories.bright_text_application_id = ? " +
              "AND stories.user_id = ? " +
              "ORDER BY  story_sets.rank";
            storySetObjects = StorySet.find_by_sql [ @story_set_sql, category.id, @bt_application.id, @user.id ]
            storySetObjects.each do | storySet |
              storySetEl = storySetsEl.add_element("StorySet");
              storySetEl.attributes["id"]   = storySet.id
              storySetEl.attributes["name"] = storySet.name
              storiesEl = storySetEl.add_element("Stories")
              @stories_sql =
                "SELECT DISTINCT stories.* FROM stories " +
                "WHERE stories.story_set_id = ? AND stories.bright_text_application_id = ? " +
                "AND stories.user_id = ? " +               
                "ORDER BY  stories.rank";
              storyEntries = Story.find_by_sql [@stories_sql, storySet.id, @bt_application.id, @user.id ]
              storyEntries.each do | storyEntry |
                storyEl = storiesEl.add_element("Story")
                storyEl.attributes["id"]   = storyEntry.id
                storyEl.attributes["name"] = storyEntry.name
                storyEl.attributes["scope"] = storyEntry.public? ? "0" : "1";
                storyEntry.toXml( storyEl )
                # puke out the xml-ified story data
              end
            end
          end
        end
        render :xml => result
      }
    end
  end
  
  
  
  def get_application_public_stories
    
    @bt_application = BrightTextApplication.where(:name=>"ApologyWiz").first #request[:application_id]
  
    respond_to do |format|
      format.xml  {

        #<Application id="12">
        # <StorySetCategories>
        #   <StorySetCategory id="15" name="safsdf"><!-- Survey -->
        #     <StorySets>
        #       <StorySet id="32" name="asdfasdf"><!-- Question -->
        #         <Stories>
        #           <Story id="1140" name="afdaf"><!-- Recombinant Answer 1 --></Story>
        #           <Story id="1143" name="bb"><!-- Recombinant Answer 2 --></Story>
        #           <Story id="1137" name="ddaa"><!-- Recombinant Answer 3 --></Story>
        #         </Stories>
        #       </StorySet>
        #     </StorySets>
        #   </StorySetCategory>
        # </StorySetCategories>
        #</Application>

        result = REXML::Document.new("<Application/>")
        if(@bt_application.present?)
          result.root.attributes["id"] = @bt_application.id.to_s
          categoriesEl = result.root.add_element("StorySetCategories")
          @categories_sql =
            "SELECT DISTINCT story_set_categories.* FROM story_set_categories " +
            "INNER JOIN story_sets ON story_set_categories.id = story_sets.category_id " +
            "INNER JOIN stories ON story_sets.id= stories.story_set_id " +
            "WHERE story_set_categories.application_id = ? " +
            "AND stories.public = TRUE " +
            "ORDER BY  story_set_categories.rank";
          categoryObjects = StorySetCategory.find_by_sql [@categories_sql, @bt_application.id]

          categoryObjects.each do | category |
            categoryEl = categoriesEl.add_element("StoryCategory")
            categoryEl.attributes["id"]   = category.id
            categoryEl.attributes["name"] = category.name
            storySetsEl = categoryEl.add_element("StorySets");

            @story_set_sql =
              "SELECT DISTINCT story_sets.* FROM story_sets " +
              "INNER JOIN stories ON story_sets.id= stories.story_set_id " +
              "WHERE  story_sets.category_id = ? AND stories.bright_text_application_id = ? " +
              "AND stories.public = TRUE " +
            "ORDER BY  story_sets.rank";
            storySetObjects = StorySet.find_by_sql [ @story_set_sql, category.id, @bt_application.id]
            storySetObjects.each do | storySet |
              storySetEl = storySetsEl.add_element("StorySet");
              storySetEl.attributes["id"]   = storySet.id
              storySetEl.attributes["name"] = storySet.name
              storiesEl = storySetEl.add_element("Stories")
              @stories_sql =
                "SELECT DISTINCT stories.* FROM stories " +
                "WHERE stories.story_set_id = ? AND stories.bright_text_application_id = ? " +
                "AND stories.public = TRUE " +
                "ORDER BY  stories.rank";
              
              storyEntries = Story.find_by_sql [@stories_sql, storySet.id, @bt_application.id]
              storyEntries.each do | storyEntry |
                storyEl = storiesEl.add_element("Story")
                storyEl.attributes["id"]   = storyEntry.id
                storyEl.attributes["name"] = storyEntry.name
                storyEl.attributes["scope"] = storyEntry.public? ? "0" : "1";
                storyEntry.toXml( storyEl )
                # puke out the xml-ified story data
              end
            end
          end
        end
        render :xml => result
      }
    end

  end

end
