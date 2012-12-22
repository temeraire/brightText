class Story < ActiveRecord::Base

  belongs_to :story_set
  
  scoped_search :on => :name
  scoped_search :on => :description
  
  def set
    setObj = StorySet.find_by_sql [ "select * from story_sets where id = ?", story_set_id ]
    return setObj[0].name unless setObj == nil || setObj.count < 1
  end

  def toXml( storyEl )
    story = JSON.parse( descriptor )

    storyEl.attributes["id"] = id.to_s;
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
  
  def populateContainerData( currentElement )
  
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
      
      existingSet = StorySet.find_by_id ( existingSetId[0].story_set_id ) if existingSetId.count == 1    
    
    
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
  
  
end
