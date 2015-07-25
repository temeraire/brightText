require 'rexml/document'

class Api::RelextsController < ActionController::Base
  after_filter{
    puts response.body
  } 

  
  def get_relexts_list
    @user_name = params[:user_name]
    @password = request[:password]

    if (@user = User.authenticate @user_name, @password)
      @bt_application = BrightTextApplication.where(:name=>"RelaxText").first
    else
      @bt_application = BrightTextApplication.where(:name=>"RelaxText").first
      @user = User.find_by_email(@user_name);
      if(@user.blank?)
        @user = User.new
        @user.email = @user_name;
        @user.password = @password
        @user.domain_id = @bt_application.domain_id
        @user.customer!
        @user.group = Group.new
        @user.group.name = "Friends"

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

        result = REXML::Document.new("<story/>")
        if(@bt_application.present?)

          @stories_sql =
            "SELECT DISTINCT stories.* FROM stories " +
            "WHERE stories.bright_text_application_id = ? " +
            "AND (stories.user_id = ? " +
            "OR stories.user_id IN (SELECT groups.user_id FROM groups INNER JOIN group_members ON groups.id = group_members.group_id " +
            "WHERE group_members.email = ? AND group_members.bright_text_application_id = ?) " +
            "OR stories.public = TRUE) " +
            "ORDER BY  stories.rank";
          storyEntries = Story.find_by_sql [@stories_sql, @bt_application.id, @user.id, @user.email, @bt_application.id ]
          index = 1
          storyEntries.each do | storyEntry |
            storyEl = result.root.add_element("pack")
            storyEl.attributes["id"]   = "relext_levelpack_" + index.to_s
            storyEl.attributes["title"] = storyEntry.name                
            storyEl.attributes["random"] = storyEntry.randomize? ? "true" : "false";
            chunks = storyEntry.descriptor.split(/\n+/)
            chunks.each do |chunk|
              item = storyEl.add_element("item")
              item.text = chunk              
            end
            index = index + 1;
            # puke out the xml-ified story data
          end
        end

        render :xml => result
      }
    end
  end

end
