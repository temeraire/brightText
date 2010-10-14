require 'open-uri'
require 'rexml/document'


class BtProxyController < ApplicationController
  def story
    resource = params[:id]
    
    uri = "http://test.contextit.com/ProcessTemplateRequest.aspx?cmd=GETXML&validationKey=75&storyID=" + resource + "&doNotEncrypt=TRUE"
    doc = REXML::Document.new(open(uri).read)
    
    story = {}
    data = [];
    contentElement = doc.root.get_elements( "//Content" )[0];
    
    contentElement.elements.each do |element|
      if element.name == "P"
        child = { "container" => populateContainerData( element ) }      
      end
      data << child if child
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
        pileChoice["text"] = pileElementElement.get_elements("Content")[0].text
        pileElements[ pileChoice["id"] ] = pileChoice
      end
      piles[ pile["id"] ] = pile
    end
    
    story["story"] = data
    story["piles"] = piles
    result = story.to_json
    if params[:callback]
      result = params[:callback] + "(" + result + ")"
    end
      
    render :js => result  #always return the json respose
    headers['content-type']='text/javascript';
  end
  
  
  
  def related
    resource = params[:id]
    
    uri = "http://test.contextit.com/ProcessTemplateRequest.aspx?cmd=getrelatedstories&storyID=" + resource + "&validationKey=1"
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
