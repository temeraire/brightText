class Story < ActiveRecord::Base

  def set
    setObj = StorySet.find_by_sql [ "select * from story_sets where id = ?", story_set_id ]
    return setObj[0].name unless setObj == nil || setObj.count < 1
  end

  def to_xml( storyEl )
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
end
