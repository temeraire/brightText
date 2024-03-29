class Story < ActiveRecord::Base

  belongs_to :story_set
  has_many :story_authors
  has_many :authors, class_name: 'User', through: :story_authors, :source => :user

  scoped_search :on => :name
  scoped_search :on => :description

  before_save :set_rank

  attr_accessible :id, :name, :story_set_id, :description, :descriptor, :user_id, :story_set, :category, :public, :rank, :randomize, :store_id

  validates :name,
              :uniqueness => { :scope => :story_set_id, :message => " is already taken. Please select another name" },
              :presence => {:message => "Please insert a name."}
 
  validates :store_id, 
              :uniqueness => { :scope => :bright_text_application_id, :message => " id is already taken. Please select another id" }

  def category
    if story_set.present?
      story_set.story_set_category.name            
    end
    ''
  end

  def category=(c)
    c = StorySetCategory.find_by_name(c) || StorySetCategory.new(name: c)
    story_set.story_set_category = c
  end

  def set_rank
    if self.rank.blank? || self.rank == 0 || self.story_set_id_changed?
      self.rank = 1 + Story.where(:story_set_id => self.story_set_id).maximum(:rank).to_i
    end
  end

  def set
    setObj = StorySet.find_by_sql [ "select * from story_sets where id = ?", story_set_id ]
    return setObj[0].name unless setObj == nil || setObj.count < 1
  end
  
  def shared_with_me(user_id)
    owner = User.find(self.user_id)
    group = Group.find_by_user_id(owner.id)
    if group.present?
      group_member = GroupMember.where(:group_id=>group.id,:user_id=>user_id).first
      if group_member.present?
        return true
      end    
    end    
    return false    
  end

  def self.dummy_story()

    dummy = Story.new
    dummy.name = "Replace me!"
    dummy.description = "Go to www.apologywiz.com/create and create your personal stuff, which will then appear here! Note: this should be done from a computer, not a mobile device, as these devices restrict what we can do with highlighted text."
    dummy.descriptor = "{\"story\":[{\"container\":[\"Go to www.apologywiz.com/create and create your personal stuff, which will then appear here!\"]},{\"container\":[]},{\"container\":[\"Note: this should be done from a computer, not a mobile device, as these devices restrict what we can do with highlighted text.\"]},{\"container\":[]}],\"piles\":{},\"storyDimensions\":[],\"meta\":{}}"
    dummy.rank = 1

    return dummy

  end

  def toXml( storyEl )
    story = descriptor && descriptor.length >= 2 ? JSON.parse(descriptor) : nil

    storyEl.attributes["id"] = id.to_s;
    rankEl = storyEl.add_element("Rank")
    rankEl.text = rank.blank? ? "0" : rank.to_s
    if story.present?    
      content = story["story"]
      puts content.class

      contentEl = storyEl.add_element("Content")
      content.each do | piece |
        #puts "VVVVVVVVVVVVVVVVVVVVVVVVV"
        #puts piece
        writeContent( piece, contentEl )
        #puts "^^^^^^^^^^^^^^^^^^^^^^^^^^"
        #puts ""
      end

      piles = story["piles"]

      pileEl = storyEl.add_element("PileContainer")
      piles.each do | id, pile |
        #puts "VVVVVVVVVVVVVVVVVVVVVVVVV"
        #puts pile
        writePile( pile, pileEl)
        #puts "^^^^^^^^^^^^^^^^^^^^^^^^^^"
        #puts ""
      end

      storyDimensions = story["storyDimensions"]

      dimensionEl = storyEl.add_element("StoryDimensionContainer")
      storyDimensions.each do | storyDimension |
        #puts "VVVVVVVVVVVVVVVVVVVVVVVVV"
        #puts storyDimension
        writeStoryDimension( storyDimension, dimensionEl)
        #puts "^^^^^^^^^^^^^^^^^^^^^^^^^^"
        #puts ""
      end
    end
  end

  def writeContent( container, element )
     puts container.class

    if container.class == "".class  # simple
      flowElement = REXML::Text.new( container )
      element.add( flowElement )
    elsif container.class == {}.class # render changepoint
      if container["container"]
        flowElement = REXML::Element.new("P")
        container["container"].each do | piece |
          writeContent( piece, flowElement )
        end
        element.add( flowElement );
      elsif container["type"] == "choice"
        flowElement = REXML::Element.new("ChangePoint")
        flowElement.attributes["type"]        = container["type"]
        flowElement.attributes["pile"]        = container["pile"]
        flowElement.attributes["pileElement"] = container["pileElement"]
        flowElement.text = container["text"]
        element.add( flowElement )
      end

    end

  end

  def writePile( pile, element )
    flowElement = REXML::Element.new("Pile")
    flowElement.attributes["id"]        = pile["id"]
    element.add( flowElement )

    pile["elements"].each do | i, pileElement |
      writePileElement( pileElement, flowElement )
    end

  end

  def writePileElement( pel, element )
    flowElement = REXML::Element.new("PileElement")
    flowElement.attributes["id"]         = pel["id"]
    flowElement.attributes["referenced"] = "true"
    value = REXML::Element.new("Content")
    value.text = pel["text"]
    flowElement.add( value )
    choices = REXML::Element.new("AllowedChoiceSets")
    if ( pel["choiceSetIds"] )
      pel["choiceSetIds"].each do | ref |
        choiceRef = REXML::Element.new("ChoiceSetRef")
        choiceRef.attributes["choiceSet"] = ref
        choices.add( choiceRef )
      end
    end

    flowElement.add( choices )
    element.add( flowElement )

  end

  def writeStoryDimension( dimension, element )
    flowElement = REXML::Element.new("StoryDimension")
    flowElement.attributes["id"]        = dimension["id"]
    flowElement.attributes["name"]      = dimension["name"]
    element.add( flowElement )

    dimension["choiceSets"].each do | choiceSet |
      writeChoiceSet( choiceSet, flowElement )
    end
  end

  def writeChoiceSet( chos, element )
    flowElement = REXML::Element.new("ChoiceSet")
    flowElement.attributes["id"]     = chos["id"]
    flowElement.attributes["name"]   = chos["name"]
    element.add( flowElement )
  end

  def self.populateContainerData( currentElement )

    data = []
    currentElement.each do | child |
      if child.is_a?(REXML::Element) && child.name == "ChangePoint"
        cp = child.attributes
        cp["text"] = child.text
        data << cp
      elsif child.is_a?(REXML::Text)
        data << child.value
      end
    end
    return data
  end

  def self.migrate_helper_import( storyId )
    story = Story.find_by_id( storyId )
    if story && story.name != nil
      puts '  ** story exists... assuming accurate data ** '
      return story.name
    end

    story = Story.new unless story
    story.save

    uri = "http://test.contextit.com/ProcessTemplateRequest.aspx?cmd=GETXML&validationKey=75&storyID=" + storyId.to_s + "&doNotEncrypt=TRUE"
    data = open(uri).read
    if ( data.length == 0 )
      puts ' ***** NO STORY ***** '
      return nil
    end

    doc = REXML::Document.new( data )
    #puts ' XML\n' + doc.to_s
    #puts '\n\n\n\n\n'


    # convert to json

    proxy = BtProxyController.new
    result = proxy.xmlToJson( doc )
    storyObj = JSON.parse( result )


    puts ' JSON\n' + result
    #puts '\n\n\n\n\n'

    # create a local db entry

    author = storyObj["meta"]["authorName"]
    user = User.find_by_name author

    user = User.new( {:name => author, :domain_id => 2} ) unless user
    user.save


    story.descriptor  = result
    story.name        = storyObj["meta"]["title"]
    story.user_id     = user.id
    story.domain_id   = 2


    # save
    story.save

    puts '  *** story created.  local story id: ' + story.id.to_s
  end

  def self.migrate_helper_related( storyId )

    existingStory = Story.find_by_id( storyId )
    if existingStory == nil
      raise 'story does not exist'
    end


    uri = "http://test.contextit.com/ProcessTemplateRequest.aspx?cmd=getrelatedstories&validationKey=75&storyID=" + storyId.to_s + "&doNotEncrypt=TRUE"
    data = open(uri).read
    if ( data.length == 0 )
      puts ' ***** NO STORY ***** '
      return
    end

    doc = REXML::Document.new( data )
    #puts ' XML\n' + doc.to_s
    #puts '\n\n\n\n\n'


    storyIds = [];
    doc.root.each_element( "//StoryId" ){ |e|  storyIds << e.text.to_i }

    puts ' RELATED STORIES: ' + storyIds.to_s
    #puts '\n\n\n\n\n'

    existingSet = nil

    # if more than 0 find whether story set was created for those stories
    if storyIds.count > 0
      existingSetId = Story.find_by_sql ["select story_set_id from stories where stories.id = ?", storyId ]
      raise ' too many story sets!!! ' if existingSetId.count > 1

      puts '  ** story set count ** ' + existingSetId.count.to_s

      existingSet = StorySet.find_by_id(existingSetId[0].story_set_id) if existingSetId.count == 1


      #  create story set if not
      if ( existingSet == nil )
        puts '  *** creating new story set'
        existingSet = StorySet.new
        existingSet.name = existingStory.name
        existingSet.domain_id = 2;
        existingSet.user_id   = existingStory.user_id
        existingSet.save
      end


      #  asocciate story with story sets
      existingStory.story_set_id = existingSet.id
      existingStory.save
      #  done

      puts '  *** asocciated story set id ' + existingStory.story_set_id.to_s + ' with story ' + existingStory.id.to_s


      queryParams = []
      storyIds.each do | id |
        story = Story.find_by_id id.to_i
        while ( story == nil || story.id != id.to_i ) do
          story = Story.new
          story.save
          story.domain_id = 2
          puts '  *** generated intermediate story ' + story.id.to_s
        end
        story.story_set_id = existingSet.id
        puts '  *** asocciated story set id ' + existingStory.story_set_id.to_s + ' with story ' + story.id.to_s
        story.save
      end
    end
  end
  
  def self.xml_to_json( root )
    
    story = {}
    data = [];
    
    story["meta"] = meta = {}
    
    story["meta"]["id"]         = root.attributes["id"];
    
    if root.attributes["templateID"] != nil   # only non-null in clone stories
      story["meta"]["templateId"] = root.attributes["templateID"];
    end
    
    meta["authorId"  ]  = root.get_elements("MetaData/Author")[0].attributes["id"] unless root.get_elements("MetaData/Author"       ).count == 0;
    meta["authorName"]  = root.get_elements("MetaData/Author/Name")[0].text        unless root.get_elements("MetaData/Author/Name"  ).count == 0;
    meta["title"     ]  = root.get_elements("MetaData/Title")[0].text              unless root.get_elements("MetaData/Title"        ).count == 0;
    meta["created"   ]  = root.get_elements("MetaData/Date/Created")[0].text       unless root.get_elements("MetaData/Date/Created" ).count == 0;
    meta["modified"  ]  = root.get_elements("MetaData/Date/Modified")[0].text      unless root.get_elements("MetaData/Date/Modified").count == 0;
    
    
    contentElement = root.get_elements( "Content" )[0];
    
    contentElement.elements.each do |element|
      if element.name == "P"
        child = { "container" => populateContainerData( element ) }   
      end
      data << child if child
    end
    if data.count == 0   # content element is the data
      data << { "container" => populateContainerData( contentElement ) } 
    end
    
    
    piles = {}
    root.get_elements( "PileContainer/Pile").each do | pileElement |
      pile = {}
      pileElements = {}
      pile["id"] = pileElement.attributes["id"]
      pile["elements"] = pileElements
      pileElement.get_elements( "PileElement" ).each do | pileElementElement |
        pileChoice = {}
        pileChoice["id"] = pileElementElement.attributes["id"]
        if pileElementElement.get_elements("Content")[0] == nil
          puts "error: pile element with ID: " + pileElementElement.attributes["id"] + " has no content"
        else
          pileChoice["text"] = pileElementElement.get_elements("Content")[0].text
        end
        pileChoiceFilter = []
        pileElementElement.get_elements("AllowedChoiceSets/ChoiceSetRef").each do | choiceSetRef |
          pileChoiceFilter << choiceSetRef.attributes["choiceSet"].to_s   
        end
        pileChoice["choiceSetIds"] = pileChoiceFilter
        pileElements[ pileChoice["id"] ] = pileChoice
      end
      piles[ pile["id"] ] = pile
    end
    
    storyDimensions = []
    root.get_elements( "StoryDimensionContainer/StoryDimension").each do | dimensionElement |
      storyDimension = {}
      choiceSets = []
      storyDimension["name"] = dimensionElement.attributes["name"];
      storyDimension["id"]   = dimensionElement.attributes["id"];
      dimensionElement.get_elements("ChoiceSet").each do | choiceSetElement |
        choiceSet = {}
        choiceSet["name"] = choiceSetElement.attributes["name"]
        choiceSet["id"]   = choiceSetElement.attributes["id"]
        choiceSets << choiceSet
      end
      storyDimension["choiceSets"] = choiceSets
      storyDimensions << storyDimension  

    end    
    
    story["story"] = data
    story["piles"] = piles
    story["storyDimensions"] = storyDimensions
    
    result = story.to_json  
    return result;
  end

end
