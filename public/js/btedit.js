
var BrightTextEditor = function( divId, editable ){

  this._story;
  this._meta            = {};
  this._piles           = {};
  this._changePoints    = [];
  this._storyDimensions = [];
  
  
  this._toneFilter = null;  // no filter
   

  var self = this;
  
  self._choiceSetAssignMode = false;
  self._choiceSetEditor     = null;


  this._btDiv = $("#" + divId );
  if ( this._btDiv[0] instanceof HTMLDivElement != true ) {
    alert("BrightTextEditor must be a DIV node");
    return;
  }

  this._btDiv[0].innerHTML = "<p><span class='plainText'></span></p>"; // blank template

    // todo: make sure this is a DIV
  this._btDiv.addClass( "btContent" );
 
  
  this.onKeyUp = function( event ){
 
    log( "keyboardup" );
    
    
    // detect that we are inside a div
    var selection = self._getSelectedText();    
    
    var range = selection.getRangeAt(0);
    
    var startContainer = selection.anchorNode.parentNode;
    var endContainer   = selection.focusNode.parentNode;
    
    if ( startContainer.nodeName == "DIV" ){
      log("unwieldy div");
      
      var buffer = new StringBuffer();
      buffer.append("<p><span class='plainText'>");
      var toKill = [];
      for ( var childIndex in startContainer.childNodes ){
        var child = startContainer.childNodes[ childIndex ];
        if ( child.nodeName == "#text" ){
          buffer.append( child.nodeValue );
          toKill.push( child );
        }
      }
      for ( var item in toKill ){
        var killIt = toKill[ item ];
        killIt.parentNode.removeChild( killIt );
      }
      buffer.append( "</p>" );
      var result = buffer.toString();
      
      log("rewriting innner div text with: " + result );
      
      var updated = $( result )[0];      
      startContainer.appendChild( updated );    
      
      range.insertNode(updated);
      range.setStartAfter(updated);
      selection.removeAllRanges();
      selection.addRange(range);             
    }
    
    if ( startContainer.nodeName == "FONT" ){
      log("**** unwieldy font ****");
      
      var buffer = new StringBuffer();
      for ( var childIndex in startContainer.childNodes ){
        var child = startContainer.childNodes[ childIndex ];
        if ( child.nodeName == "#text" ){
          buffer.append( child.nodeValue );
        }
      }
      
      var result = buffer.toString();
      
      log("rewriting innner div text with: " + result );
      
      var updated = null;
      if ( startContainer.parentNode.nodeName != "SPAN" ){
        updated = $( "<span class='plainText'>" + result + "</span>" )[0];
      } else {
        updated = document.createTextNode( result );
      }
      startContainer.parentNode.insertBefore( updated, startContainer );
      startContainer.parentNode.removeChild( startContainer );
      
     // range.removeNode( startContainer );
      range.insertNode(updated);
      range.setStartAfter(updated);
      selection.removeAllRanges();
      selection.addRange(range);             
      
    }    
    
    if ( self._btChangeCallback ) self._btChangeCallback(); 
    
  }
  
  this._btDiv.bind( "keyup", this.onKeyUp );
  
  this._btDiv.bind( "keydown", function( event ) {
    log( "keydown" );

  });
  
  
  this._btChangeCallback = null;
  
  this.onChange = function( callback ){
    this._btChangeCallback = callback;
  }
  
  this.toneGradients = function(){
    var result = [];
    result.push( { id: null, name: "Any" } );
    if ( typeof(this._storyDimensions[0]) != 'undefined' ){
      for ( var i = 0; i < this._storyDimensions[0].choiceSets.length; i++ ){
        result.push( this._storyDimensions[0].choiceSets[i] );
      }
    }
    return result;
  }
  
  this.handleToneSelection = function( toneId ){
    self._toneFilter = toneId;
    log(" tone filter: " + toneId );
    self.rewrite();
    this.toData();
  }
  
  this.selectedTone = function(){
    return self._toneFilter;  
  }
  
  this.renderData = function( data ){
    log("renderData");
    
    self._toneFilter = null;
  
    self._meta            = data["meta"];
    self._story           = data["story"];
    self._piles           = data["piles"]; 
    self._storyDimensions = data["storyDimensions"];
  
    for ( var pile in self._piles ){
      var pileMeta = self._piles[ pile ];
      var id = pileMeta["id"];
      _modelFactory.recordUsedId( id );
      
      for ( var pileElement in pileMeta["elements"] ){
        var pileElementMeta = pileMeta["elements"][ pileElement ];
        id = pileElementMeta["id"];
        _modelFactory.recordUsedId( id );   
      }
    }
    
    for ( var dimension in self._storyDimensions ){
      var dimensionMeta = self._storyDimensions[ dimension ];
      id = dimensionMeta[ "id" ];
      _modelFactory.recordUsedId( id );
      
      for ( var choiceSet in dimensionMeta["choiceSets"] ){
        var choiceSetMeta = dimensionMeta["choiceSets"][ choiceSet ];
        id = choiceSetMeta[ "id" ];
        _modelFactory.recordUsedId( id );
      }
    }
    
  
  
    self.renderStory();
    
    if ( self._btChangeCallback ) self._btChangeCallback();
  }

  
  this.toData = function(){
    log("toData");
    
    var start = this._btDiv[0];
    var story = [];
    this._streamChildData( start, story );
    this._story = story;    
    return {"story": story, "piles": this._piles, storyDimensions: this._storyDimensions, "meta": this._meta };
  }
  
  
  this.toString = function(){
    log("toString");

    var start = this._btDiv[0];
    var resultBuffer = new StringBuffer();
    this.bufferChildData( start, resultBuffer );
    return resultBuffer.toString();
  }
  
  
  this.bufferChildData = function( node, buffer )
  {
    //log( "bufferChildData.  NodeName: " + node.nodeName );
    var child = node.firstChild;
    while ( child !=  null){
      switch (child.nodeName){
        case "P":  // really the only thing we expect at this level, if the editor is working properly
          this.bufferChildData( child, buffer );
          buffer.append("\n\n");
          break;
        case "DIV":
          this.bufferChildData( child, buffer );
          buffer.append("\n");        
          break;
        case "SPAN":
          this.bufferChildData( child, buffer );
          break;
        case "BR":
          buffer.append("\n");        
          break;       
        case "FONT":
          this.bufferChildData( child, buffer );
          break;
        case "#text":
          buffer.append( child.nodeValue.replace(/\xA0/g ,' ') );
          break;
        default:
          log("unsupported edit node: " + child.nodeName );
          break;
      }
      child = child.nextSibling;
      
    }
  
  }
  
  this._streamChildData = function( node, story )
  {
    //log( "streamChildData.  NodeName: " + node.nodeName );
    var child = node.firstChild;
    while ( child !=  null){
      switch (child.nodeName){
        case "P":  // really the only thing we expect at this level, if the editor is working properly
          var kidz = [];
          var container = { "container": kidz };
          this._streamChildData( child, kidz );
          story.push( container );
          story.push( { "container": [] } );
          break;
          
   /*   
        case "DIV":
          this.bufferChildData( child, buffer );
          buffer.append("\n");        
          break;
          
        case "BR":
          buffer.append("\n");        
          break;             
    */      
        case "SPAN":
          if ( child["dataIndex"] != undefined ){ // it's a changepoint
            log(" serializing changepoint ");
            cp = this._changePoints[ parseInt( child["dataIndex"] ) ];
            story.push( cp );
          } else {
            this._streamChildData( child, story );
          }
          break;
       
        case "#text":
          story.push( child.nodeValue.replace(/\xA0/g ,' ') );
          break;
        default:
          log("unsupported edit node: " + child.nodeName );
          break;
      }
      child = child.nextSibling;
      
    }
  }
  
  
  this._getPileFor = function( changepoint )
  {
    var pile = this._piles[ changepoint["pile"] ];
    return pile;
  }  
  
  
  /**
   *  Story rendering 
   */
  this.renderStory = function( randomize, preserveChoice)
  {
    if ( randomize ) randomize = true;
    else randomize = false;
    
    this._changePoints = new Array();
    storyContentDiv = this._btDiv;
    
    while( storyContentDiv[0].firstChild ){
      storyContentDiv[0].removeChild( storyContentDiv[0].firstChild );
    }
    
    //log("have data of length: " + this._story.length);
    
    for ( var c = 0; c <  this._story.length; c++ ){
      var pos = new DataPositioner( c );
      this.renderContainer( storyContentDiv, this._story[c]["container"], pos, randomize, preserveChoice );
    }
  }


  this.renderContainer = function( div, data, pos, randomize, preserveChoice )
  {
    //log( "rendering container of length: " + data.length );
    
    if ( data.length == 0 ) return;  // ignore line-break containers
    var container = $("<p/>");
    
    div.append( container );
    
    for ( var  i = 0; i < data.length; i++ ){
      var el = data[i];
      if ( typeof( el ) == "object" ){ // changepoint
        var c = this.renderChangepoint( el, pos.cloneWithIndex( i ), randomize, preserveChoice );
      } else {
        var c = this.renderText( el, pos.cloneWithIndex( i ) );
      }
      c["val"] = c[0].className;
      container.append( c );
    }
  }

  this._undimTimeout;
  this._nodeCount = 0;

  this.renderChangepoint = function( el, pos, randomize, preserveChoice )
  {
    if ( randomize && preserveChoice === el ){
      randomize = false;
    }
    var cpIndex = this._changePoints.length; 
    this._changePoints.push( el ); 
    
    var p = $("<span/>");
    p[0]["dataIndex"] = cpIndex;
    p.addClass( "changePoint" );
    p.addClass( "changePointResting");
    var value = randomize ? this._randomPileElement( el ) : el['text']
    
    var t = document.createTextNode( value );
    p.append( t );


    var self = this;
    p.bind( "mouseover", function(){
      p.removeClass("changePointResting").addClass( "changePointHover" );
      
      if (!editable){
        self._cpSelect( event );
      } else if( self._choiceSetAssignMode ) {
        self._cpEditChoiceSet( event );
      }
    });
    
    p.bind( "mouseout", function(){
      p.removeClass("changePointHover").addClass( "changePointResting" );
    });
    
    p.bind( "click", function(){
      if ( editable ){  
        self._cpSelect( event );
      }
    });
    
    return p;
  }


  this.renderText = function( el, pos )
  {
    var p = $("<span/>");
    p.addClass( "plainText" );
    var t = document.createTextNode( el );
    p.append( t );
    return p;
  }
  
  this.editChoicesets = function( )
  {
    if ( self._choiceSetEditor ) return;
    self._choiceSetEditor = new $.choiceSetEditor( self._storyDimensions, {
      onClose: self._onChoiceEditComplete, 
      onDataChange: function() { 
        if ( self._btChangeCallback ) self._btChangeCallback(); 
      },
      onAssignModeEnter: self._onChoiceSetAssignEnter,
      onAssignModeLeave: self._onChoiceSetAssignLeave,
    });
    self._choiceEdit = true;
  }
  
  this._onChoiceEditComplete = function(){
    self._choiceEdit          = false;
    self._choiceSetAssignMode = false;
    self._choiceSetEditor     = null;
  }
  
  this._onChoiceSetAssignEnter = function(){
    self._choiceSetAssignMode = true;
  }
  
  this._onChoiceSetAssignLeave = function(){
    self._choiceSetAssignMode = false;
  }  
  
  this._randomPileElement = function( cp )
  {
    var pileId = cp.pile;
    var pile = this._piles[ pileId ];
    
    var pileEls = [];
    for ( var i in pile.elements ){
      var add = true;
      var pileElement = pile.elements[i];
      if ( typeof( pileElement.choiceSetIds ) != 'undefined' && pileElement.choiceSetIds.length > 0 && self._toneFilter ){
        add = false;
        for ( var j = 0; j < pileElement.choiceSetIds.length; j++ ){
          var choice = pileElement.choiceSetIds[j];
          if ( choice == self._toneFilter ) add = true;
        }
      }    
      if ( add ) pileEls.push( pileElement );
    }
    
    var index = Math.floor(  Math.random() * pileEls.length );
    log( "returning index " + index + " out of " + pileEls.length + " total ");
    
    return pileEls.length > 0 ? pileEls[ index ].text : "[NO MATCH IN TONE]";
  }
  
  
  this._createChangepointFromSelection = function()
  {
    var selection = this._getSelectedText();
    //alert("selected text: " + selection );
  
  
    var startContainer = selection.anchorNode.parentNode;
    var endContainer   = selection.focusNode.parentNode;
    
    if ( startContainer != endContainer ) {
      alert("Changepoints must be within the same paragraph and may not span other Changepoints.");
      return;
    }
    
    log("startContainer: " + startContainer + " endContainer: " + endContainer );
    
    var path = [];
    
    var currentContainer = startContainer;
    path.push( startContainer );
    while ( currentContainer != endContainer ){  // TODO: this equality fails to detect end when start is a change point and end is plain text
      if ( currentContainer.nextSibling  == null ){
        log( "null sibling in " + currentContainer.id );
        break;
      }
      currentContainer = currentContainer.nextSibling;
      path.push( currentContainer );
    }
    
    log("number of containers in path: " + path.length );
    
    if ( path.length > 1 ) {
      alert("new changepoints cannot span existing changepoints");
      return;
    }
    
    // WE ARE IN BUSINESS!!!   *************** 

    var startOffset = selection.anchorOffset;
    var endOffset   = selection.focusOffset;
    
    if ( endOffset < startOffset ){
      var v = endOffset;
      endOffset = startOffset;
      startOffset = v;
    }
    
    log( " start offset: " + startOffset + " end offset: " + endOffset );
    
    var text = startContainer.firstChild.nodeValue;
    
    //alert("text to subdivide: " + text );
    
    var data = [];
    data.push( text.substring( 0, startOffset ) );
    data.push( text.substring( startOffset, endOffset) );
    data.push( text.substring( endOffset ) );
    
    //log( "split the original into: " + Object.toJSON( data ) ); 
    
    var pileElement    = _modelFactory.createPileElement( data[1] );
    var pile           = _modelFactory.createPile( pileElement );
    var changePoint    = _modelFactory.createChangepoint( pile, pileElement );
    
    //log( "created pile: " + Object.toJSON( pile ));
    
    //log( "created changepoint: " + Object.toJSON( changePoint ) );
    
    this._piles[ pile.id ] = pile;
    
    var cp = this.renderChangepoint( changePoint );
    var rt = this.renderText( data[0] );
    
    var parent = startContainer.parentNode;
    parent.insertBefore( rt[0], startContainer );
    parent.insertBefore( cp[0], startContainer );
    startContainer.innerHTML = data[2]; 
    
    if ( self._btChangeCallback ) self._btChangeCallback();

    self._cpEdit( cp[0] );
  }  
  
  
  this._cpToPlainText = function ( el )
  {
    var rt = this.renderText(  el.firstChild.nodeValue  );
    el.parentNode.insertBefore(  rt[0], el );
    el.parentNode.removeChild( el );
    // TODO: delete any data associated with this cp (splice)
    if ( this._btChangeCallback ) this._btChangeCallback(); 
    
  }
  
  this._cpDelete = function( el )
  {
    el.parentNode.removeChild( el );  
    // TODO: delete any data associated with this cp (splice)
    if ( this._btChangeCallback ) this._btChangeCallback(); 
    
  }
  
  this._cpEdit = function( el )
  {
    var changepoint = this._changePoints[ el["dataIndex"] ];
    var pile = this._getPileFor( changepoint )
    
    var options = [];

    $.pileEditor( pile, options, _modelFactory, self );
  }
  
  
  this._cpSelect = function( event )
  {
    var el = event.target;
    var changepoint = this._changePoints[ el["dataIndex"] ];
    var pile = this._getPileFor( changepoint )
    
    var options = [];
    
    var self = this;
    for ( var id in pile["elements"] ){
      var choiceSetIds = [];
      
      if ( typeof( pile["elements"][id]["choiceSetIds"] ) != 'undefined' ) {
        choiceSetIds = pile["elements"][id]["choiceSetIds"];
      }
      
      options.push( {label: pile["elements"][id]["text"], action: this._selectionCallback( pile, id, el ), choiceSetIds: choiceSetIds  } );
    }
    $.choiceMenu( event, options, self._toneFilter );    
  }
  
  
  this._cpEditChoiceSet = function( event )
  {
    var el = event.target;
    var changepoint = this._changePoints[ el["dataIndex"] ];
    var pile = this._getPileFor( changepoint )
    
    var options = [];
    var spec = { choiceSetAssignment: this._choiceSetEditor.choiceSetAssignment(), storyDimensionSpec: this._choiceSetEditor.storyDimensionSpec() };
    
    var self = this;
    var chosCount = 0;
    for ( var id in pile["elements"] ){
      var choiceSetIds = [];
      
      if ( typeof( pile["elements"][id]["choiceSetIds"] ) != 'undefined' ) {
        choiceSetIds = pile["elements"][id]["choiceSetIds"];
      }
        
      options.push( {label: pile["elements"][id]["text"], action: this._pileElementChoiceSetAppliedCallback( pile, id, el ), choiceSetIds: choiceSetIds });
      if ( choiceSetIds.length > chosCount ){
        chosCount = choiceSetIds.length;
      }
      
    }
    $.choiceSetMenu( event, options, spec, chosCount );    
  }  
  
    
  this._cpUpdateSelection = function ( pile, elementId, el )
  {
    var element = pile["elements"][ elementId ];
    var value = element.text;
    
    cp = this._changePoints[ parseInt( el["dataIndex"] ) ];
    cp.text = value;
    cp.pileElement = elementId;
    
    log( " apply pile element: " + value + " to element " + el );
    el.innerHTML = value;
    if ( element.choiceSetIds.length > 0 ){
      // check whether the current tone already belongs to one of the choiceSets in this element
      var toneChangeRequired = true;
      $.each( element.choiceSetIds, function(){ 
        if ( this == self._toneFilter ) toneChangeRequired = false;
      });
      
      if ( toneChangeRequired ){
        // pick a tone from the list of this element's tones
        var choiceIndex = Math.floor( Math.random() * element.choiceSetIds.length );
        self._toneFilter = element.choiceSetIds[ choiceIndex ];
          
        // and auto-rewrite the whole document, keeping this one the way it is
        this.renderStory( true, cp );
        this.toData();      
      }
    }    
    if ( this._btChangeCallback ) this._btChangeCallback(); 
  }
  
  this._cpUpdateChoiceSet = function ( pile, elementId, el, choiceSetId )
  {
    var validOp = false;
    var element = pile["elements"][ elementId ];
    if ( choiceSetId != null ){
      if ( typeof (element.choiceSetIds) == 'undefined' ){
        element.choiceSetIds = [];
        validOp = true;
      }
      if (-1 == $.inArray( choiceSetId, element.choiceSetIds) ) {
        element.choiceSetIds.push( choiceSetId );
        validOp = true;
      }
    } else {
      delete element.choiceSetIds;
      validOp = true;
    }
    if ( this._btChangeCallback ) this._btChangeCallback();
    return validOp;
  }  
  
  this._selectionCallback = function( pile, elementId, el ){
    var self = this;
    return function( event ){
      self._cpUpdateSelection( pile, elementId, el );
    };
  }
  
  this._pileElementChoiceSetAppliedCallback = function( pile, elementId, el ){
    var self = this;
    return function( event, choiceSetId ){
      return self._cpUpdateChoiceSet( pile, elementId, el, choiceSetId );
    };  
  }
  
  this._getSelectedText = function()
  {
    var selection = '';
    if (window.getSelection){
      log("one");
      selection = window.getSelection();
    }
    else if (document.getSelection){
      log("two");
      selection = document.getSelection();
    }
    else if (document.selection){
      log("three");
      selection = document.selection.createRange().text;
    }
    return selection;
  }  
  
  
  this._attachContextMenu = function()
  {
    
    var self = this;
    $.conmenu( "DIV.btContent", [{
        selector:"SPAN.plainText",
        choices:[{
            label:"Create Changepoint",
            action:function( element ){
              //alert(" convert to BT ");
              self._createChangepointFromSelection();
            }
          },
          {
            label:"About...",
            action:function( element ){
              alert("BrightText Wand 1.0");
            }
          }]
        },
        {
          selector:"DIV.btContent",
          choices:[{
            label:"About...",
            action:function( element ){
              alert("BrightText Wand 1.0");
            }
          }]
        },
        {
        selector:"SPAN.changePoint",
        choices:[{
          label:"Edit Changepoint",
          action:function( element ){
            self._cpEdit( element );
          }
        },{
          label:"Delete Changepoint",
          action:function( element ){
            self._cpDelete( element );
          }
        },{
          label:"Convert to Plain Text",
          action:function( element ){
            self._cpToPlainText( element );
          }          
        },
        {
          label:"About...",
          action:function( element ){
            alert("BrightText Wand 1.0");
          }
        }]
      }] );        
  }
  
  if ( editable ){ 
    this._btDiv[0].contentEditable = true; 
    this._attachContextMenu();
  }  

  this.rewrite = function()
  {
    log("rewrite");
    this.renderStory( true );
    this.toData();
    if ( self._btChangeCallback ) self._btChangeCallback();
    
  }
  
  this.commitEdits = function()
  {
    if ( this._btChangeCallback ) this._btChangeCallback(); 
  }

}  // end BrightTextEditor




function StringBuffer() { 
  this.buffer = []; 
} 


StringBuffer.prototype.append = function append(string) { 
  this.buffer.push(string); 
  return this; 
}; 


StringBuffer.prototype.toString = function toString() { 
  return this.buffer.join(""); 
}; 



var DataPositioner = function( containerIndex ){
  this._containerIndex = containerIndex;
  this._dataIndex = -1;
  
  this.setContainerIndex = function( i ){
    this._containerIndex = i;
  }
  
  this.setDataIndex = function( i ){
    this._dataIndex = i;
  }
  
  this.cloneWithIndex = function( i ){
    var positioner = new DataPositioner( this._containerIndex );
    positioner.setDataIndex( i );
    return positioner;
  }
  
  this.getContainerIndex = function() {
    return this._containerIndex;
  }
  
  this.getDataIndex = function(){
    return this._dataIndex;
  }
}



/**************************************************/
/**         MODEL OBJECT FACTORY CLASS           **/
/**************************************************/
var ObjectFactory = function(){
  this._idCounter = -1;

  this.createChangepoint = function( pile, pileElement )
  {
    var changePoint = {"type":"choice","pile":pile.id,"pileElement":pileElement.id,"text":pileElement.text};   
    return changePoint;
  }
  
  this.createPile = function( pileElement )
  {
    var pile = { "id": this.generateId(), "elements": {} };
    if ( pileElement ){
      pile.elements[pileElement["id"]] = pileElement; 
    }
    return pile;
  }
  
  this.createPileElement = function( text )
  {
    var element = {"id":this.generateId(), "text":text };
    return element;
  }
  
  this.createStoryDimension = function( name ){
    var element = {"id":this.generateId(), "name":name, choiceSets:[] };
    return element;    
  }
  
  this.createChoiceSet = function( name ){
    var element = {"id":this.generateId(), "name":name };
    return element;    
  }  
  

  this.generateId = function(){
    return this._idCounter--;
  }
  
  this.recordUsedId = function( val ){
    if ( val < this._idCounter ){
      this._idCounter = val - 1;
      log("ObjectFactory::updated id counter: " + this._idCounter );
    }
  }
}



/**********  GLOBAL INSTANCE  ***********/
var _modelFactory = new ObjectFactory();


/**
 *
 */
(function($) {
  var choices;
  
  $.choiceMenu = function( event, options, filter ){
    choices = options;
    showmenu( event, options, filter );
  };
  
  //defaults
  $.choiceMenu.containerType = 'div';
  $.choiceMenu.choicesType = 'div';
  
  var container = document.createElement($.choiceMenu.containerType);
  
  $(document).ready(function(){
    $(container).hide().attr('id','choiceMenu').css('position','absolute').appendTo(document.body);
  });
  
  function showmenu(event, choices, filter ){
    event.stopPropagation();
    resetMenu();
    $(document.body).mousedown(function( event ){
      if ( $(event.target).hasClass("largeChoiceMenu")){
        event.stopPropagation();
        event.preventDefault();
        return;
      }
      resetMenu();
      $(document.body).unbind('mousedown');
    });    
    
    $(container).removeClass("largeChoiceMenu");
    
    var tonedChoices = [];
    var untonedChoices = [];
    
    $.each(choices,function(){
      var add = true;
      if ( this.choiceSetIds && this.choiceSetIds.length > 0 && filter ){
        add = false;
        for ( var i = 0; i < this.choiceSetIds.length; i++ ){
          var choice = this.choiceSetIds[i];
          if ( choice == filter ){
            add = true;
          } 
        }
      }
      if ( add ){
        tonedChoices.push( this );      
      } else {
        untonedChoices.push( this );
      }
    });
    
    $.each( tonedChoices,   function() { self._drawChoice(this, true) } );
    $.each( untonedChoices, function() { self._drawChoice(this, false)} );
    
    if ( $(container).height() > 400 ){
      $(container).addClass("largeChoiceMenu");
    }    
		var size = {
      'height':$(window).height(),
      'width':$(window).width(),
      'sT': $(window).scrollTop(),
      'cW':$(container).width(),
      'cH':$(container).height()
    };
		$(container).css({
			'left': ((event.clientX + size.cW) > size.width ? ( event.clientX - size.cW) : event.clientX),
			'top': ((event.clientY + size.cH) > size.height && event.clientY > size.cH ? (event.clientY + size.sT - size.cH) : event.clientY + size.sT),

		}).show();
		$(container).addClass( 'contextContainer' );

    return false;
  }
  
  self._drawChoice = function( choice, toned ){
      var actionElement =  $("<div></div>").text(choice.label);
      actionElement.addClass( 'menuItem' );
      if ( !toned ) actionElement.addClass("untoned");
      actionElement.mouseover( function( event ) {
        $(event.target).removeClass('menuItem').addClass( 'highlightedMenuItem' );
      });
      actionElement.mouseout( function( event ) {
        $(event.target).removeClass('highlightedMenuItem').addClass( 'menuItem' );
      });          
      
      actionElement.mousedown( function(clickEvent){
        clickEvent.stopPropagation();
        choice.action( event.target );
        resetMenu();
      });
      
      actionElement.appendTo(container);
      log("width: " + actionElement.width() );
      if ( actionElement.width() > 300 ) actionElement.width( 300 );
            
      
      log( "  CONTAINER HEIGHT:  "  + $(container).height() );
      log( "  CONTAINER width:  "  + $(container).width() );
      if ($(container).width() > 300 ) actionElement.width( 300 );
    }  
  
  
  
  function resetMenu(){
    $(container).hide().empty();
  }
  
})(jQuery);


/**
 *
 */
(function($) {
  var choices;
  
  $.choiceSetMenu = function( event, options, spec, chosCount ){
    this._spec      = spec;
    this._chosCount = chosCount;
    var self        = this;
  
    //defaults
    //$.choiceSetMenu.containerType = 'div';
   // $.choiceSetMenu.choicesType = 'div';
    
    var container = $("#choiceSetMenu");
    if ( typeof( container[0] ) == 'undefined' ){ // jQuery returns an object when there isn't one in the DOM
      container = $("<div id='choiceSetMenu' style='position:absolute'/>");
      $('body').append( container );
    }
    
    //$(document).ready(function(){

    //    });
    
    this._showmenu = function (event, choices){
      event.stopPropagation();
      self._resetMenu();
      $(document.body).mousedown(function( ){
        self._resetMenu();
      });    
      
      //$(container).height( 10 )
      $.each( choices,function(){
        var action  = this.action;
        var label   = this.label;
        var chosIds = this.choiceSetIds;
        self._renderAction( action, label, chosIds);     
      });
      //if ( $(container).height() > 400 ){
      //  $(container).addClass("choiceEditor-huge");
      //}       
      var size = {
        'height':$(window).height(),
        'width':$(window).width(),
        'sT': $(window).scrollTop(),
        'cW':$(container).width(),
        'cH':$(container).height()
      };
      $(container).css({
        'left': ((event.clientX + size.cW) > size.width ? ( event.clientX - size.cW) : event.clientX),
        'top': ((event.clientY + size.cH) > size.height && event.clientY > size.cH ? (event.clientY + size.sT - size.cH) : event.clientY + size.sT),
  
      }).show();
      $(container).addClass( 'contextContainer' );
  
      return false;
    }
    
    this._resetMenu = function(){
      $(container).hide().empty();
    }
    
    this._renderAction = function( action, label, choiceSetIds){
      var actionElement =  $("<div class='menuItem' style='height:19px;'/>");
      actionElement.appendTo(container);
      var chosInPileElement = choiceSetIds.length;
      
      for ( var i = 0; i < self._chosCount + 1; i++ ){
        var choiceSetIndicator = self._renderChoiceSetIndicator( actionElement, choiceSetIds, i );
      }
      
      var textContainer = $("<div class='choiceSetTextContainer'/>").html( label );
      actionElement.append( textContainer );
      
      
      actionElement.mousedown( function(clickEvent){
        var colors = self._spec.storyDimensionSpec;    
        clickEvent.stopPropagation();        
        var color = colors[self._spec.choiceSetAssignment];
        if ( color == null ){
          color = null;
          var indicator = actionElement[0].firstChild;
          while ( indicator != null ){
            $(indicator).css( 'background-color', "#ffffff" );
            indicator.style.backgroundColor = null;

            indicator = indicator.nextSibling;
          }
        }
        if ( action( event.target, self._spec.choiceSetAssignment )) { // apply the choice set element
          choiceSetIndicator.css('background-color', color );        
        }
      });
      
      actionElement.mouseover( function( event ) {
        actionElement.removeClass('menuItem').addClass( 'highlightedMenuItem' );
      });
      actionElement.mouseout( function( event ) {
        actionElement.removeClass('highlightedMenuItem').addClass( 'menuItem' );
      });          
            
    }
    
    this._renderChoiceSetIndicator = function( actionElement, choiceSetIds, i ){
      var colors = self._spec.storyDimensionSpec;    
      var choiceSetIndicator = $("<div class='choiceSetIndicator ui-corner-all'/>");
      var mappedCount = choiceSetIds.length - self._chosCount + i;
      var bgcolor = null;
      if ( mappedCount >= 0 && i < self._chosCount ){
        bgcolor = colors[ choiceSetIds[ mappedCount ] ];
      }
      choiceSetIndicator.css('background-color',  bgcolor);
      actionElement.append( choiceSetIndicator );
      return choiceSetIndicator;
    }
    
    
    self._showmenu( event, options );

  }
})(jQuery);


/**
 *
 */
(function($) {
  var choices;
  var submenu;
  var btedit;
  
  $.pileEditor = function( pile, options, modelFactory, btEditor ){
    choices = options;
    btedit = btEditor;
    showEditor( pile, options, modelFactory);
  };
  
  //defaults
  $.pileEditor.containerType = 'div';
  
  
  var modelFactory;
  
  var container = document.createElement($.pileEditor.containerType);
  $(container).addClass( "choiceEditor" );
  
  $(document).ready(function(){
    $(container).hide().attr('id','pileEditor').css('position','absolute').appendTo(document.body);
  });
  
  function showEditor( pile, options, factory ){
    //event.stopPropagation();
    modelFactory = factory;
    resetMenu();
    $(document.body).mousedown(function( event ){
      resetMenu( event );
    });    
    
    $(container).removeClass("choiceEditor-huge");    
    for ( var id in pile.elements ){
      renderPileElement( id, pile );
    }
    
    renderBlankElement( pile );
     
    if ( $(container).height() > 400 ){
      $(container).addClass("choiceEditor-huge");
    } 
    
    
		var size = {
      'height':$(window).height(),
      'width':$(window).width(),
      'sT': $(window).scrollTop(),
      'cW':$(container).width(),
      'cH':$(container).height()
    };
		$(container).css({
			'left': ((event.clientX + size.cW) > size.width ? ( event.clientX - size.cW) : event.clientX),
			'top': ((event.clientY + size.cH) > size.height && event.clientY > size.cH ? (event.clientY + size.sT - size.cH) : event.clientY + size.sT),

		}).show();

    return false;
  }
  
  function renderPileElement( id, pile )
  {
      var pileElement = pile.elements[ id ];

      var elementContainer =  $("<div class='choiceEditContainer'/>");
      var elementDeleteImg =  $("<a href='#' class='choiceDeleteButton'><img src='/images/delete_new.png'/></a>");
      
      elementDeleteImg.click( function() {
        log( "deleting pile element: " + id );
        elementContainer.remove();
        delete pile.elements[id];
      });
      
      elementContainer.append( elementDeleteImg );
      
      elementContainer.bind("mouseover", function( event ) {
          $(".choiceEditContainer").removeClass("choiceEditContainerHighlight");
          elementContainer.addClass( "choiceEditContainerHighlight" );
          
        });
      
      if ( pileElement.text.length < 32 ){
        elementEditField =  $("<input class='choiceEditField' type='text'></input>");
        elementEditField[0].value = pileElement.text;
      }
      else {
        elementEditField =  $("<textarea></textarea>");
        if ( pileElement.text.length > 150 ){
          elementEditField.addClass("choiceEditTextAreaHuge");
        } else {
          elementEditField.addClass("choiceEditTextArea");
        }
        elementEditField.val( pileElement.text );      
      }
      elementEditField[0]["pel"] = pileElement;
      elementContainer.append( elementEditField );      
      
      
      elementEditField.bind( "keyup", function( event ) {
        event.target["pel"].text = event.target.value;
      } );
      
      /*
      var elementExpandImg = $("<img src='/images/expand.png' class='expandPileElement'/>");
      
      elementContainer.append( elementExpandImg );
      
      elementExpandImg.bind( "mouseover", function( event ) {
        showToneDimensions( pileElement, event );
      } );
      
      elementExpandImg.bind( "mouseout", function( event ){
        timedHideToneDimensions( pileElement, event );
      } );
      
      */

      elementContainer.appendTo(container);
   }
  
  function showToneDimensions( pileElement, event )
  {
    log ("must show tone dimensions");
    submenu = $.elementDimensionsView( event, pileElement );
    log( "sub: " + submenu );
  }
  
  function timedHideToneDimensions( pileElement, event  )
  {
    log ("must hide tone dimensions");
  }
  
  
  function renderBlankElement( pile )
  {
    var elementContainer =  $("<div class='choiceEditContainer'/>");
    var elementPlusImg =  $("<img src='/images/plus_new.png' class='elementPlusIcon'/>");
    elementContainer.append( elementPlusImg );
    var elementEditField =  $("<input class='choiceEditField' type='text'></input>");
    elementEditField[0]["pel"] = null;
    elementContainer.append( elementEditField );
    
    elementContainer.bind("mouseover", function( event ) {
        $(".choiceEditContainer").removeClass("choiceEditContainerHighlight");
        elementContainer.addClass( "choiceEditContainerHighlight" );
        
      });   
      
    elementEditField.bind( "keyup", function( event ) {
      if ( event.target.value.length > 0 ){
        log("do have something indeed!");
      
      }
      else{
        log("eh");
      }
    
    });
      
    elementEditField.bind( "change", function( event ) {
      log( "create this");
      $(event.target).unbind( "change");
      var pileElement = modelFactory.createPileElement( event.target.value );
      pile.elements[pileElement.id] = pileElement;
      this["pel"] = pileElement;
      elementPlusImg.remove();
      elementDeleteImg =  $("<a href='#' class='choiceDeleteButton'><img src='/images/delete_new.png'/></a>");
      elementDeleteImg.click( function() {
        log( "deleting pile element: " + pileElement.id );
        elementContainer.remove();
        delete pile.elements[pileElement.id];
      });
      elementDeleteImg.insertBefore( elementEditField );      
      
      /*
      var elementExpandImg = $("<img src='/images/expand.png' class='expandPileElement'/>");
      elementExpandImg.insertAfter( elementEditField );
      
      elementExpandImg.bind( "mouseover", function( event ) {
        showToneDimensions( pileElement, event );
      } );
      
      elementExpandImg.bind( "mouseout", function( event ){
        timedHideToneDimensions( pileElement, event );
      } );
      */      
            
      $(this).bind( "keyup", function( event ) {
        event.target["pel"].text = event.target.value;
      } );            
      
      renderBlankElement( pile );
    } );

    elementContainer.appendTo(container);
    
    elementEditField.focus();
    
    if ( $(container).height() > 400 ){
      $(container).addClass("choiceEditor-huge");
    }    
  }
  
  function deleteCallback( id ){
    return function( event ) { 
      event.stopPropagation();
      log( "Deleting Pile Element: " + id );
    };
  } 
  
  

  
  function resetMenu( event ){
    var tg = event ?  event.target : event;    
    while ( tg != null ){
      if ( container == tg || ( submenu && submenu[0] == tg )) return;
      tg = tg.parentNode;
    }
    $(container).hide().empty();
    if ( btedit ) btedit.commitEdits();
  }
  
})(jQuery);



/**
 *
 */
(function($) {
  var originalTarget;
  
  $.elementDimensionsView = function( event, pileElement ){
    originalTarget = event.target.parentNode;
    return loadView( event, pileElement );
  };
  
  //defaults
  $.choiceMenu.containerType = 'div';
  $.choiceMenu.choicesType = 'div';
  
  var container = document.createElement($.choiceMenu.containerType);
  
  $(document).ready(function(){
    $(container).hide().attr('id','pileElementMenu').css('position','absolute').appendTo(document.body);
  });
  
  function loadView(event, pileElement){
    resetMenu( null );
    
    $(document.body).mouseover(function( event ){
      resetMenu( event );
    });    
   
   
    renderToneSelector( "Friendliness", ["Friendly", "Neutral", "Coarse", "Demanding", "Offensive"], container );
    renderToneSelector( "Formality", ["Formal", "Respectful", "Casual", "Conversational", "Slang"], container );
    renderToneSelector( "Verbocity", ["Terse", "Consice", "Wordy", "Blabbering"], container );

    
		var size = {
      'height':$(window).height(),
      'width':$(window).width(),
      'sT': $(window).scrollTop(),
      'cW':$(container).width(),
      'cH':$(container).height()
    };
		$(container).css({
			'left': ((event.clientX + size.cW) > size.width ? ( event.clientX - size.cW) : event.clientX) + 5,
			'top': ((event.clientY + size.cH) > size.height && event.clientY > size.cH ? (event.clientY + size.sT - size.cH) : event.clientY + size.sT ) - 20,

		}).show();
		$(container).addClass( 'pileElementOptContainer' );

    return $(container);
  }
  
  function renderToneSelector( dimensionName, dimensionGradients, container)
  {
    var elementContainer = $("<div style='padding: 20px 15px 5px 15px; text-size:10pt'/>");   
    
    var gradientValue = $( '<div id="gradient_' + dimensionName + '" style="float:right; padding: 0px 0px 0px 0px; font-weight:bold;">' + dimensionGradients[0] + '</div>' );
    var gradientLabel = $( '<div style="padding:0px 0px 5px 0px;">' + dimensionName + ': </div>');    

    var scroller = $("<div style='width:200px; height:.5em; cursor:pointer' id='scroller_" + dimensionName + "'/>");
    
    gradientValue.appendTo( elementContainer );
    gradientLabel.appendTo( elementContainer );
    scroller     .appendTo( elementContainer );
    
    elementContainer.appendTo( container );
    
        
    $( "#scroller_" + dimensionName ).slider({
          value:0,
          min: 0,
          max: dimensionGradients.length - 1,
          step: 1,
          range: true,
          slide: function( event, ui ) { 
            var s1 = ui.values[0];
            var s2 = ui.values[1];
            
            if ( s1 == s2 ){
              $( "#gradient_" + dimensionName )[0].innerHTML = dimensionGradients[ ui.value ];
            } else {
              $( "#gradient_" + dimensionName )[0].innerHTML = dimensionGradients[ s1 ] + " - " + dimensionGradients[ s2 ];
            }             
            
           }
        });
   
    scroller.children().css( 'width', '0.9em' ).css( 'height', '0.9em' ).css( "cursor","pointer");  
    return elementContainer;
  }
  
  function resetMenu( event ){
    var tg = event ?  event.target : event;
    while ( tg != null ){
      if ( container == tg || originalTarget == tg) return;
      tg = tg.parentNode;
    } 
    $(container).hide().empty();
  }
  
})(jQuery);


function log( msg )
{
  if ( typeof ( console ) != "undefined" ){
    console.log( msg );
  }
}


(function($) {
  $.choiceSetEditor = function( data, options ){
    
    var self = this;
    
    self._data = data;
    self._choiceMode = "create";
    self._assignSetId = null;
  
    self._init = function(){
      var editor = $("<div id='choiceset-editor'><div style='width:100%; margin: 0px 15px 20px 3px'<form><div id='choiceset-mode-selector'><input type='radio' id='mode-new' name='radio'/><label for='mode-new' >New</label><input type='radio' id='mode-edit' name='radio'/><label for='mode-edit' >Edit</label><input type='radio' id='mode-assign' name='radio' checked='checked'/><label for='mode-assign'>Assign</label></div></form></div><div id='choice-set-editor-body' style='width:100%; height:100%'></div></div>");
      $('body').append(editor);
      
      colors = ["#ffffff", "#ff9999", "#99ff99", "#9999ff", "#ffff99", "#ff99ff", "#99ffff"];
      
      
      var dialog = $("#choiceset-editor").dialog({close: function(){
        $("#choiceset-editor").remove();
        options.onClose(); 
      }});
      
      dialog[0].parentNode.style.width = '223px';
      dialog[0].parentNode.style.height = '380px';
      dialog[0].style.overflowX = 'hidden';
      dialog[0].style.overflowY = 'hidden';
      
      $("#choiceset-mode-selector").buttonset();
      
      $("#mode-edit").click( self._renderEditUI );
      $("#mode-assign").click( self._renderAssignUI );
      $("#mode-new").click( self._renderNewUI );
      
      
      
      self._dialogBody = $("#choice-set-editor-body");
      self._clearBody();
        

      if ( self._data.length > 0 ){   // TODO: key off the number of choicesets... only support 1 for now...
        $("#mode-new").button("disable");
        $("#mode-assign").click();
      } else {
        $("#mode-edit").button("disable");
        $("#mode-assign").button("disable");
        $("#mode-new").click();
      }
    }
    
    self._renderNewUI = function(){
      self._clearBody();
      $("#choice-set-editor-body").append( $("<div style='float:left; display:block'>Name: <input type='text' id='choiceset-name' style='width:143px' value=''>") );
      $("#choice-set-editor-body").append( $("<button id='save-new-choiceset' style='float:right; margin:40px 5px 0px 0px'>Create</button>" ).button().button("disable").click( function() {
        self._finishCreateChoiceSet( $("#choiceset-name")[0].value );
      }) );
      $("#choiceset-name").keyup( function( event ) {
        if ( event.target.value.length > 0 ){
          $("#save-new-choiceset").button("enable");
        } else {
          $("#save-new-choiceset").button("disable");
        }
      });    
    }
    
    self._renderAssignUI = function(){
      self._clearBody();    
      // append the name
      // append the name
       $("#choice-set-editor-body").append(  $("<div style='width:100%; height:30px'></div>"));
       
       var csName = $("<div style='width:100%; text-align:center; display:block; font-size:14pt; font-face:Lucida Sans Unicode; font-weight:bold; padding-bottom:20px'></div>")
       $("#choice-set-editor-body").append( csName );
       csName[0].innerHTML = self._data[0].name;       
      
  
      self._storyDimensionSet = {};
      self._renderAssignment( null, "UNASSIGNED", colors[0] );
            
      for ( var i = 0; i < self._data[0].choiceSets.length; i++ ){
        self._renderAssignment( self._data[0].choiceSets[i].id, self._data[0].choiceSets[i].name, colors[i+1] );
        self._storyDimensionSet[ self._data[0].choiceSets[i].id ] = colors[ i + 1 ];
      }
    }
    
    self._renderEditUI = function(){
      self._clearBody();    
      
      var csName = $("<div style='width:100%; height:30px; margin-bottom: 20px'>Name: <input id='choiceset-name' type='text' style='width:140px'></div>")
      $("#choice-set-editor-body").append( csName );
      $("#choiceset-name")[0].value = self._data[0].name;
                 
      $("#choiceset-name").bind( "keyup", function( event ) {
        self._data[0].name = event.target.value;
        options.onDataChange();
      } );            
                   
                   
      for ( var id in self._data[0].choiceSets ){
        self._renderChoiceSet( id );
        
      }
      
      self._renderBlankElement( );       
    }
    
    self._choiceContainerTemplate = "<div style='width:180px; height:30px; border: 1px dashed black; margin:2px'>"
    self._choiceIconTemplate      = "<div style='float:left; width:20px; height:20px; margin:5px; background-color:%COLOR%' class='ui-corner-all'>";
    self._choiceLabelTemplate     = "<div style='float:left;  width:100px; height:25px; padding: 7px 0px 0px 5px;'></div>";
    self._newChoiceTemplate       = "<div style='float:left;  width:100px; height:30px; padding: 2px 0px 0px 5px;'><input type='text' style='width:100px'></input></div>";

    
    self._renderAssignment = function( id, name, color )
    {
      var choiceContainer = $( self._choiceContainerTemplate );
      var choiceLabel = $( self._choiceLabelTemplate);
      choiceLabel[0].innerHTML = name;
      choiceContainer.append( $(self._choiceIconTemplate.replace( "%COLOR%", color )) );
      choiceContainer.append( choiceLabel );
      choiceContainer.addClass("choiceSetAssignContainer");
      choiceContainer.bind("click", function( event ) {
          $(".choiceSetAssignContainer").removeClass("choiceSetAssignContainerHighlight");
          choiceContainer.addClass( "choiceSetAssignContainerHighlight" );
          options.onAssignModeEnter();
          self._assignSetId = id;
        });
      $("#choice-set-editor-body").append( choiceContainer ) ;
  
    }
    
    self._renderChoiceSet = function( id )
    {
        var choiceSet = self._data[0].choiceSets[ id ];
  
        var elementContainer =  $("<div class='choiceSetEditContainer'/>");
        var elementDeleteImg =  $("<a href='#' class='choiceSetDeleteButton'><img src='/images/delete_new.png'/></a>");
        
        elementDeleteImg.click( function() {
          log( "deleting choiceset: " + id );
          elementContainer.remove();
          delete self._data[0].choiceSets[id];
          options.onDataChange();
        });
        
        elementContainer.append( elementDeleteImg );
        
        elementContainer.bind("mouseover", function( event ) {
            $(".choiceSetEditContainer").removeClass("choiceSetEditContainerHighlight");
            elementContainer.addClass( "choiceSetEditContainerHighlight" );
            
          });
        
        elementEditField =  $("<input class='choiceSetEditField' type='text'></input>");
        elementEditField[0].value = choiceSet.name;
        elementEditField[0]["chos"] = choiceSet;
        elementContainer.append( elementEditField );
        
        
        elementEditField.bind( "keyup", function( event ) {
          event.target["chos"].name = event.target.value;
          options.onDataChange();
        } );        
  
        elementContainer.appendTo(self._dialogBody);
     }

    
    self._renderBlankElement = function( )
    {
      var elementContainer =  $("<div class='choiceSetEditContainer'/>");
      var elementPlusImg =  $("<img src='/images/plus_new.png' class='choiceSetPlusIcon'/>");
      elementContainer.append( elementPlusImg );
      var elementEditField =  $("<input class='choiceSetEditField' type='text'></input>");
      elementEditField[0]["pel"] = null;
      elementContainer.append( elementEditField );
      
      elementContainer.bind("mouseover", function( event ) {
          $(".choiceSetEditContainer").removeClass("choiceSetEditContainerHighlight");
          elementContainer.addClass( "choiceSetEditContainerHighlight" );
          
        });   
        
      elementEditField.bind( "keyup", function( event ) {
        if ( event.target.value.length > 0 ){
          log("do have something indeed!");
        
        }
        else{
          log("eh");
        }
      
      });
        
      elementEditField.bind( "change", function( event ) {
        log( "create this");
        $(event.target).unbind( "change");
        var choiceSet = _modelFactory.createChoiceSet( event.target.value );
        self._data[0].choiceSets.push( choiceSet );
        options.onDataChange();
        this["chos"] = choiceSet;
        elementPlusImg.remove();
        elementDeleteImg =  $("<a href='#' class='choiceSetDeleteButton'><img src='/images/delete_new.png'/></a>");
        elementDeleteImg.click( function() {
          log( "deleting pile element: " + pileElement.id );
          elementContainer.remove();
          delete self._data[0].choiceSets[choiceSet.id];
          options.onDataChange();
        });
        elementDeleteImg.insertBefore( elementEditField );      
        
        $(this).bind( "keyup", function( event ) {
          event.target["chos"].name = event.target.value;
          options.onDataChange();
        } );            
        
        self._renderBlankElement( );
      } );
  
      elementContainer.appendTo(self._dialogBody);
      
      elementEditField.focus();
    }
    
    self._deleteCallback = function( id ){
      return function( event ) { 
        event.stopPropagation();
        log( "Deleting Pile Element: " + id );
      };
    }     
      
      
      
       
    
    self._clearBody = function()
    {
      while( self._dialogBody[0].firstChild ){
         $(self._dialogBody[0].firstChild).remove();
      }
      options.onAssignModeLeave();
    }
    
    self._finishCreateChoiceSet = function( name ){
      // TODO: add data
      var ch = _modelFactory.createStoryDimension( name );
      self._data.push( ch );
      
      $("#mode-new").button("disable");  // only one choiceset allowed
      $("#mode-edit").button("enable").click();      
      $("#mode-assign").button("enable");    
      
      self._renderEditUI();
      
      options.onDataChange();
      
    }
    
    self._init();
    
    
    self.choiceSetAssignment = function(){
      return self._assignSetId;
    }
    
    self.storyDimensionSpec = function(){
      return self._storyDimensionSet;
    }
  }
})(jQuery);  