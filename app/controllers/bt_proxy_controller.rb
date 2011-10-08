require 'open-uri'
require 'rexml/document'
require 'rexml/formatters/transitive'


class BtProxyController < ApplicationController

  def story
    resource = params[:id]
    
    #uri = "http://localhost/contextit/btrails/Story" + resource + ".xml"
    
    uri = "http://test.contextit.com/ProcessTemplateRequest.aspx?cmd=GETXML&validationKey=75&storyID=" + resource + "&doNotEncrypt=TRUE"
    
    
    doc = REXML::Document.new(open(uri).read)

    result = xmlToJson( doc )

    if params[:callback]
      result = params[:callback] + "(" + result + ")"
    end
      
    render :js => result  #always return the json respose
    headers['content-type']='text/javascript';
  end
  
  
  
  def related
    resource = params[:id]
    
    uri = "http://localhost/contextit/btrails/RelatedStories.xml"
    
    #uri = "http://test.contextit.com/ProcessTemplateRequest.aspx?cmd=getrelatedstories&storyID=" + resource + "&validationKey=1"
    doc = REXML::Document.new(open(uri).read)
    
    stories = [];
    doc.root.each_element( "//StoryId" ){ |e|  stories << e.text }    
    
    #@data = {}
    #@data["params"] = params;
    #@data["relatedStories"] = stories;
    #@data["uri"
    
    @result = stories.to_json
    if params[:callback]
      @result = params[:callback] + "(" + @result + ")"
    end
      
    render :js => @result  #always return the json respose
    headers['content-type']='text/javascript';
  end 
  
  
  def xmlToJson( doc )
    
    story = {}
    data = [];
    
    story["meta"] = meta = {}
    
    story["meta"]["id"]         = doc.root.attributes["id"];
    
    if doc.root.attributes["templateID"] != nil   # only non-null in clone stories
      story["meta"]["templateId"] = doc.root.attributes["templateID"];
    end
    
    meta["authorId"  ]  = doc.root.get_elements("/Story/MetaData/Author")[0].attributes["id"];
    meta["authorName"]  = doc.root.get_elements("/Story/MetaData/Author/Name")[0].text;
    meta["title"     ]  = doc.root.get_elements("/Story/MetaData/Title")[0].text;
    meta["created"   ]  = doc.root.get_elements("/Story/MetaData/Date/Created")[0].text;
    meta["modified"  ]  = doc.root.get_elements("/Story/MetaData/Date/Modified")[0].text;
    
    
    contentElement = doc.root.get_elements( "//Content" )[0];
    
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
    doc.root.get_elements( "//Pile").each do | pileElement |
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
    doc.root.get_elements( "//StoryDimension").each do | dimensionElement |
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
  
  
  def save
    data = params[:data]
    
    puts 'SAVE data:\n\n' + data;
    
    
    story = JSON.parse( data )
    
    #puts story.toXML
    
    
    doc = REXML::Document.new("<Story><MetaData><Author><Name/></Author><Title/><Date><Created/><Modified/></Date></MetaData><Content/><PileContainer/><StoryDimensionContainer/></Story>")
    
    
    meta = story["meta"]
    
    doc.root.attributes["id"] = meta["id"];
    
    
    if meta["templateId"] != nil   # only non-null in clone stories
      doc.root.attributes["templateID"] = meta["templateId"]
    end
    
    doc.root.get_elements("/Story/MetaData/Author")[0].attributes["id"] = meta["authorId"  ] 
    doc.root.get_elements("/Story/MetaData/Author/Name")[0].text        = meta["authorName"] 
    doc.root.get_elements("/Story/MetaData/Title")[0].text              = meta["title"     ]
    doc.root.get_elements("/Story/MetaData/Date/Created")[0].text       = meta["created"   ]
    doc.root.get_elements("/Story/MetaData/Date/Modified")[0].text      = meta["modified"  ] 
    
    content = story["story"]
    
    puts content.class
    
    content.each do | piece |
      #puts "VVVVVVVVVVVVVVVVVVVVVVVVV"
      #puts piece
      writeContent( piece, doc.root.get_elements("/Story/Content")[0] );      
      #puts "^^^^^^^^^^^^^^^^^^^^^^^^^^"
      #puts ""    
    end
    

    piles = story["piles"]
    
    piles.each do | id, pile | 
      #puts "VVVVVVVVVVVVVVVVVVVVVVVVV"
      #puts pile
      writePile( pile, doc.root.get_elements("/Story/PileContainer")[0] )
      #puts "^^^^^^^^^^^^^^^^^^^^^^^^^^"
      #puts ""       
    end
    
    storyDimensions = story["storyDimensions"]
    
    storyDimensions.each do | storyDimension |
      #puts "VVVVVVVVVVVVVVVVVVVVVVVVV"
      #puts storyDimension
      writeStoryDimension( storyDimension, doc.root.get_elements("/Story/StoryDimensionContainer")[0] )
      #puts "^^^^^^^^^^^^^^^^^^^^^^^^^^"
      #puts ""     
    end
    
    resultDoc = submitStory( doc )
    
    
    result = xmlToJson( resultDoc );
    render :js => result  #always return the json respose
    headers['content-type']='text/javascript';    
   
    #result = data;
    #render :xml => doc

  end
  
  
  def submitStory( storyDoc )
    serviceUrl = "http://test.contextit.com/processtemplaterequest.aspx"
    #storyText = storyDoc.toString
    
    
    storyText = ""
    tr = REXML::Formatters::Transitive.new( storyText )   
    storyDoc.write( storyText )
    
    puts
    puts "*************************************************************************"
    puts "**************                BT DOCUMENT              ******************"
    puts storyDoc
    puts "*************************************************************************"
    puts     
    
    completeRequest = "cmd=loadxml&validationkey=12&&value=" + URI.encode_www_form_component( storyText )
    
    puts
    puts "*************************************************************************"
    puts "**************                  BT DATA                ******************"
    puts completeRequest
    puts "*************************************************************************"
    puts 
    
=begin    
    url = URI.parse( serviceUrl )
    res = Net::HTTP.start(url.host, url.port) { |http|
      http.post(url.path, completeRequest)
    }    
    
    doc = REXML::Document.new( res.read_body )
=end
    doc = storyDoc
    
    puts
    puts "*************************************************************************"
    puts "**************               BT RESPONSE               ******************"
   # puts  res.read_body 
    puts "*************************************************************************"
    puts     
    
    return doc
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
