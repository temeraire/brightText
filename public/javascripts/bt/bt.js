
function loadStory( id )
{

  var scriptTag = document.createElement("script");
  scriptTag.id = "story_data";
  scriptTag.src = "/proxy/" + id + "/story?callback=loadStoryCallback";
  head = document.getElementsByTagName("head").item(0);  
  head.appendChild( scriptTag );

}

var _story;
var _piles;

var _changePoints = new Array();;

function loadStoryCallback( data )
{
  _story = data["story"];
  _piles = data["piles"];

  renderStory();

}

function renderStory( )
{
  var _changePoints = new Array();;
  storyContentDiv = $("btContent");
  
  while( storyContentDiv.firstChild ){
    storyContentDiv.removeChild( storyContentDiv.firstChild );
  }
  
  log("have data of length: " + _story.length);
  
  for ( var c = 0; c <  _story.length; c++ ){
    renderContainer( storyContentDiv, _story[c]["container"] );
  }
}

function renderContainer( div, data )
{
  log( "rendering container of length: " + data.length );
  
  var container = document.createElement("p");
  div.appendChild( container );
  
  
  for ( var  i = 0; i < data.length; i++ ){
    var el = data[i];
    if ( typeof( el ) == "object" ){ // changepoint
      var c = renderChangepoint( el, data, i );
    } else {
      var c = renderText( el, data, i );
    }
    c["val"] = c.className;
    container.appendChild( c );
  }
}

var _undimTimeout;
var _nodeCount = 0;

function renderChangepoint( el )
{
  var cpIndex = _changePoints.length; 
  _changePoints.push( el ); 
  
  
  var p = document.createElement("span");
  el["view"] = p;
  p["dataIndex"] = cpIndex;
  p.className = "changePoint"
  var t = document.createTextNode( el['text'] );
  p.appendChild( t );
  p.id = "cp_" + _nodeCount++;

  p.addEventListener( "mouseover", function(){
    p.className = "changePointHover";
    if ( _undimTimeout ){
      clearTimeout( _undimTimeout ); 
      _undimTimeout = null;
    } else {
      dimTheRest( p );
    }
  }, false );
  p.addEventListener( "mouseout", function(){
    setTimeout("unhighlightSelf('" + p.id + "')", 1000 );
    _undimTimeout = setTimeout( "undimAll( )", 3000 );
  }, false );
  
  p.addEventListener( "click", function(){
    processChangePointClick( p );
  }, false );
  
  return p;
}


function renderText( el, data, index )
{
  var p = document.createElement("span");
  p.className = "plainText";
  p["dataArray"] = data;
  p["dataIndex"] = index;
  var t = document.createTextNode( el );
  p.appendChild( t );
  p.addEventListener( "mouseup", function(){
    log(" span is up ");
  }, false );
  return p;
}

function processChangePointClick( domEl )
{
  log("processChangePointClick()");

  var dataId = domEl["dataIndex"];
  cp = _changePoints[ dataId ];
  beginChangepointEdit( cp );
}

function calculateAbsoluteCoords( el )
{
  var obj = el;
  var x = 0;
  var y = 0;
  while ( obj ){
    log(" offsetLeft: " + obj.offsetLeft );
    log(" offsetTop: "  + obj.offsetTop );  
    x += obj.offsetLeft;
    y += obj.offsetTop;
    obj = obj.offsetParent;
  }
  
  var result = {};
  result["left"]   = x;
  result["top"]    = y;
  result["width"]  = el.offsetWidth;
  result["height"] = el.offsetHeight;
  return result;
  
}


function unhighlightSelf( id ){
    domEl = $(id);
    domEl.className = "changePoint_dimmed";
}

function dimTheRest( domEl ){
  var parent = $("btContent");
  for ( var c = 0; c < parent.childNodes.length; c++ ){
    var container = parent.childNodes[c];  
    for ( var i = 0; i < container.childNodes.length; i ++ ){    
      var child = container.childNodes[i];
      if ( child != domEl ){
        child.className = child.className + "_dimmed";
      }
    }
  }
}

function undimTheRest( domEl ){
  _undimTimeout = null;
  var parent = domEl.parentNode;
  for ( var c = 0; c < parent.childNodes.length; c++ ){
    var container = parent.childNodes[c];  
    for ( var i = 0; i < container.childNodes.length; i ++ ){
      var child = container.childNodes[i];
      if ( child != domEl ){
        child.className = child["val"];
      }
    }
  }
}

function undimAll(){
  _undimTimeout = null;
  var parent = $("btContent");
  for ( var c = 0; c < parent.childNodes.length; c++ ){
    var container = parent.childNodes[c];
    for ( var i = 0; i < container.childNodes.length; i ++ ){
      var child = container.childNodes[i];
      child.className = child["val"];
    }
  }
}


function beginChangepointEdit( changepoint )
{
  placeVeilOverlay();
  placeControlsOverlay();
  
  pile = getPileFor( changepoint )
  
  var i = 1;
  for ( var id in pile["elements"] ){
    var ui = $("selectionBox_" + i );
    if ( id == changepoint["pileElement"] ){
      log("default pile element: " + id );
      continue;
    }
    renderTextIn( $("selectionBoxText_" + i ), pile["elements"][id]["text"] );
    //setupElementSelection( ui, changepoint, pile, id );
    var clickHandler = new ChangePointSelectionEventHandler( ui, changepoint, pile, id );
    ui.addEventListener( "click", clickHandler, false );
    _changePointSelectionHelper.registerSelectionHandler( ui, clickHandler );
    i++;
    if ( i > 4 ){
      log("**********  REACHED THE 4 CHOICE LIMITATION  **************");
      break;
    }
  }
  
  while ( i <= 4 ){
    renderTextIn( $("selectionBoxText_" + i ), "" );
    i++;
  }
    
  var defaultButton = $("highlightDisplay");
  renderTextIn( $("selectedElementDisplay"), changepoint["text"] );
  var clickHandler = new ChangePointSelectionEventHandler( defaultButton, changepoint, pile, changepoint["pileElement"] );
  defaultButton.addEventListener( "click", clickHandler, false );
  _changePointSelectionHelper.registerSelectionHandler( defaultButton, clickHandler );  

}



var ChangePointSelectionHelper = function()
{
  this._eventListeners = {};
  
  this.registerSelectionHandler = function( ui, handler ) {
    this._eventListeners[ui.id] = handler;
  }
  
  this.clearSelectionHandlers = function(){
    for ( var id in this._eventListeners ){
      var listener = this._eventListeners[ id ];
      if ( listener != null ){
        var domEl = $( id );
        domEl.removeEventListener( "click", listener, false );
      }
    }
  }

}

_changePointSelectionHelper = new ChangePointSelectionHelper();

var ChangePointSelectionEventHandler = function ( uiEl, changepoint, pile, elementId )
{
  this.handleEvent = function( target )
  {
    _changePointSelectionHelper.clearSelectionHandlers();
    log("in callback... id: " + elementId );
    applyPileElementTo( changepoint, pile, elementId );      
  }
}


function applyPileElementTo( changepoint, pile, elementId )
{
  log( "applyig pile element: " + elementId );
  changepoint["pile"] = pile["id"];
  changepoint["pileElement"] = elementId;
  changepoint["text"] = pile["elements"][ elementId ]["text"];
  renderTextIn( changepoint["view"], changepoint["text"] );
  removeControlsOverlay();
  removeVeilOverlay();
}


function getPileFor( changepoint )
{
  // TODO; lookup the piel based on foreign key in the changepoint
  
  var pile = _piles[ changepoint["pile"] ];
  
  /*
  var pile = {"id":"123"};
  var elements = { "1":{"text":"foo", "id": "1"}, "2": {"text":"bar", "id":"2"}, "3":{"text":"blah", "id":"3"}};
  pile["elements"] = elements;
  */
  
  log(" pile: " + Object.toJSON( pile ) );
  return pile;
}


function renderTextIn( para, text )
{
  log(" Rendering text [" + text + "] in " + para );
  while ( para.firstChild ){
    para.removeChild( para.firstChild );
  }
  para.appendChild( document.createTextNode( text ) );
}


function createChangepointFromSelection()
{
  var selection = getSelectedText();
  //alert("selected text: " + selection );


  var startContainer = selection.anchorNode.parentNode;
  var endContainer   = selection.focusNode.parentNode;
  
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
  
  var container      = startContainer["dataArray"];
  var containerIndex = startContainer["dataIndex"];
  
  //log( "modifying element: " + containerIndex + " in array: " + container );
  
  var startOffset = selection.anchorOffset;
  var endOffset   = selection.focusOffset;
  
  var original = container[containerIndex];
  
  var data = [];
  data.push( original.substring( 0, startOffset ) );
  data.push( original.substring( startOffset, endOffset) );
  data.push( original.substring( endOffset ) );
  
  log( "split the ofriginal into: " + Object.toJSON( data ) ); 
  
  var pileElement    = _modelFactory.createPileElement( data[1] );
  var pile           = _modelFactory.createPile( pileElement );
  var changePoint    = _modelFactory.createChangepoint( pile, pileElement );
  
  log( "created pile: " + Object.toJSON( pile ));
  
  log( "created changepoint: " + Object.toJSON( changePoint ) );
  
  _piles[ pile.id ] = pile;
  container.splice( containerIndex, 1, data[0], changePoint, data[2] );
  
  // TODO: re-render????
  renderStory();
  

}

function getSelectedText()
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



function placeControlsOverlay()
{
  var controls = $("textControlsOverlay");
  
  controls.style.display="inline";
  
  var textOverlayCoord = calculateAbsoluteCoords( controls );
  var editorCoord      = calculateAbsoluteCoords( $("btContent") );
  
  log(" controls coord: " + Object.toJSON( textOverlayCoord ) );
  log(" editor coord: " + Object.toJSON( editorCoord ) );
  
  var desiredLeft = ( editorCoord["width"]  - textOverlayCoord["width"]  ) / 2 + editorCoord["left"];
  var desiredTop  = ( editorCoord["height"] - textOverlayCoord["height"] ) / 2 + editorCoord["top"] ;
  
  controls.style.left = desiredLeft + "px";
  controls.style.top  = desiredTop  + "px";
}

function removeControlsOverlay()
{
  $("textControlsOverlay").style.display="none";
}

function placeVeilOverlay()
{
  var veil = $("veil");
  veil.style.display="inline";
  
  var coord = calculateAbsoluteCoords( $("btContent") );
  
  for ( var d in coord ){
    veil.style[ d ] = coord[ d ] + "px";
  }
}

function removeVeilOverlay()
{
  $("veil").style.display="none";
  
  
  
}

function log( msg )
{
  if ( typeof ( console ) != "undefined" ){
    console.log( msg );
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

