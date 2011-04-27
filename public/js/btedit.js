
var BrightTextEditor = function( divId, editable ){

  this._story;
  this._piles         = {};
  this._changePoints  = [];
   

  var self = this;


  this._btDiv = $("#" + divId );
  if ( this._btDiv[0] instanceof HTMLDivElement != true ) {
    alert("BrightTextEditor must be a DIV node");
    return;
  }

  this._btDiv[0].innerHTML = "<p><span class='plainText'>&nbsp</span></p>"; // blank template

    // todo: make sure this is a DIV
  this._btDiv.addClass( "btContent" );
 
  
  this._btDiv.keyup( function( event ) {
    log( "keyboardup" );
    if ( self._btChangeCallback ) self._btChangeCallback();
  });
  
  this._btDiv.bind( "keydown", function( event ) {
    log( "keydown" );

  });
  
  
  this._btChangeCallback = null;
  
  this.onChange = function( callback ){
    this._btChangeCallback = callback;
  }
  
  
  this.renderData = function( data ){
    log("renderData");
  
    this._story = data["story"];
    this._piles = data["piles"];    
  
    this.renderStory();
    
    if ( this._btChangeCallback ) this._btChangeCallback();
  }
  
  
  
  
  this.toData = function(){
    log("toData");
    
    var start = this._btDiv[0];
    var story = [];
    this._streamChildData( start, story );
    this._story = story;    
    return {"story": story, "piles": this._piles };

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
    log( "bufferChildData.  NodeName: " + node.nodeName );
    var child = node.firstChild;
    while ( child !=  null){
      switch (child.nodeName){
        case "P":  // really the only thing we expect at this level, if the editor is working properly
          this.bufferChildData( child, buffer );
          buffer.append("\n");
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
        case "#text":
          buffer.append( child.nodeValue );
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
    log( "streamChildData.  NodeName: " + node.nodeName );
    var child = node.firstChild;
    while ( child !=  null){
      switch (child.nodeName){
        case "P":  // really the only thing we expect at this level, if the editor is working properly
          var kidz = [];
          var container = { "container": kidz };
          this._streamChildData( child, kidz );
          story.push( container );
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
          story.push( child.nodeValue );
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
  this.renderStory = function( randomize )
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
      this.renderContainer( storyContentDiv, this._story[c]["container"], pos, randomize );
    }
  }


  this.renderContainer = function( div, data, pos, randomize )
  {
    //log( "rendering container of length: " + data.length );
    
    var container = $("<p/>");
    
    div.append( container );
    
    for ( var  i = 0; i < data.length; i++ ){
      var el = data[i];
      if ( typeof( el ) == "object" ){ // changepoint
        var c = this.renderChangepoint( el, pos.cloneWithIndex( i ), randomize );
      } else {
        var c = this.renderText( el, pos.cloneWithIndex( i ) );
      }
      c["val"] = c[0].className;
      container.append( c );
    }
  }

  this._undimTimeout;
  this._nodeCount = 0;

  this.renderChangepoint = function( el, pos, randomize )
  {
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
    });
    
    p.bind( "mouseout", function(){
      p.removeClass("changePointHover").addClass( "changePointResting" );
    });
    
    p.bind( "click", function(){
      self._cpSelect( event );
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
  
  
  this._randomPileElement = function( cp )
  {
    var pileId = cp.pile;
    var pile = this._piles[ pileId ];
    
    var pileEls = [];
    for ( var i in pile.elements ){
      pileEls.push( pile.elements[i] );
    }
    
    var index = Math.floor(  Math.random() * pileEls.length );
    log( "returning index " + index + " out of " + pileEls.length + " total ");
    
    return pileEls[ index ].text;
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

    $.pileEditor( pile, options );
  }
  
  
  this._cpSelect = function( event )
  {
    var el = event.target;
    var changepoint = this._changePoints[ el["dataIndex"] ];
    var pile = this._getPileFor( changepoint )
    
    var options = [];
    
    var self = this;
    for ( var id in pile["elements"] ){
      options.push( {label: pile["elements"][id]["text"], action: this._selectionCallback( pile, id, el ) } );
    }
    $.choiceMenu( event, options );    
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
    if ( this._btChangeCallback ) this._btChangeCallback(); 
  }
  
  this._selectionCallback = function( pile, elementId, el ){
    var self = this;
    return function( event ){
      self._cpUpdateSelection( pile, elementId, el );
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
  

  this.generateId = function(){
    return this._idCounter--;
  }
}



/**********  GLOBAL INSTANCE  ***********/
var _modelFactory = new ObjectFactory();


/**
 *
 */
(function($) {
  var choices;
  
  $.choiceMenu = function( event, options ){
    choices = options;
    showmenu( event, options );
  };
  
  //defaults
  $.choiceMenu.containerType = 'div';
  $.choiceMenu.choicesType = 'div';
  
  var container = document.createElement($.choiceMenu.containerType);
  
  $(document).ready(function(){
    $(container).hide().attr('id','choiceMenu').css('position','absolute').appendTo(document.body);
  });
  
  function showmenu(event, choices){
    event.stopPropagation();
    resetMenu();
    $(document.body).mousedown(function( ){
      resetMenu();
    });    
    
    $.each(choices,function(){
      var action = this.action;
      actionElement =  $(document.createElement($.conmenu.choicesType)).html(this.label);
      
      actionElement.addClass( 'menuItem' );
      
      actionElement.mouseover( function( event ) {
        $(event.target).removeClass('menuItem').addClass( 'highlightedMenuItem' );
      });
      actionElement.mouseout( function( event ) {
        $(event.target).removeClass('highlightedMenuItem').addClass( 'menuItem' );
      });          
      
      actionElement.mousedown( function(clickEvent){
        clickEvent.stopPropagation();
        action( event.target );
        resetMenu();
      });
      
      actionElement.appendTo(container);
    });
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
  
  function resetMenu(){
    $(container).hide().empty();
  }
  
})(jQuery);


/**
 *
 */
(function($) {
  var choices;
  var submenu;
  
  $.pileEditor = function( pile, options ){
    choices = options;
    showEditor( pile, options );
  };
  
  //defaults
  $.pileEditor.containerType = 'div';
  $.pileEditor.elementContainerType = 'div';
  $.pileEditor.elementContainerType = 'input';
  
  
  var modelFactory = new ObjectFactory();
  
  var container = document.createElement($.pileEditor.containerType);
  $(container).addClass( "choiceEditor" );
  
  $(document).ready(function(){
    $(container).hide().attr('id','pileEditor').css('position','absolute').appendTo(document.body);
  });
  
  function showEditor( pile, options ){
    //event.stopPropagation();
    resetMenu();
    $(document.body).mousedown(function( event ){
      resetMenu( event );
    });    
    
    for ( var id in pile.elements ){
      renderPileElement( id, pile );
      
    }
    
    renderBlankElement( pile );
     
    
    
    
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
      var elementDeleteImg =  $("<a href='#' class='choiceDeleteButton'><img src='images/delete_new.png'/></a>");
      
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
      
      elementEditField =  $("<input class='choiceEditField' type='text'></input>");
      elementEditField[0].value = pileElement.text;
      elementEditField[0]["pel"] = pileElement;
      elementContainer.append( elementEditField );
      
      
      elementEditField.bind( "keyup", function( event ) {
        event.target["pel"].text = event.target.value;
      } );
      
      var elementExpandImg = $("<img src='images/expand.png' class='expandPileElement'/>");
      
      elementContainer.append( elementExpandImg );
      
      elementExpandImg.bind( "mouseover", function( event ) {
        showToneDimensions( pileElement, event );
      } );
      
      elementExpandImg.bind( "mouseout", function( event ){
        timedHideToneDimensions( pileElement, event );
      } );
      
      

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
    var elementPlusImg =  $("<img src='images/plus_new.png' class='elementPlusIcon'/>");
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
      elementDeleteImg =  $("<a href='#' class='choiceDeleteButton'><img src='images/delete_new.png'/></a>");
      elementDeleteImg.click( function() {
        log( "deleting pile element: " + pileElement.id );
        elementContainer.remove();
        delete pile.elements[pileElement.id];
      });
      elementDeleteImg.insertBefore( elementEditField );      
      
      
      var elementExpandImg = $("<img src='images/expand.png' class='expandPileElement'/>");
      elementExpandImg.insertAfter( elementEditField );
      
      elementExpandImg.bind( "mouseover", function( event ) {
        showToneDimensions( pileElement, event );
      } );
      
      elementExpandImg.bind( "mouseout", function( event ){
        timedHideToneDimensions( pileElement, event );
      } );
            
            
      $(this).bind( "keyup", function( event ) {
        event.target["pel"].text = event.target.value;
      } );            
      
      renderBlankElement( pile );
    } );

    elementContainer.appendTo(container);
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