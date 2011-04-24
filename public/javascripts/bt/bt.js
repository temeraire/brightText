
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
  _changePoints = new Array();;
  storyContentDiv = $("#btContent");
  
  while( storyContentDiv[0].firstChild ){
    storyContentDiv[0].removeChild( storyContentDiv[0].firstChild );
  }
  
  log("have data of length: " + _story.length);
  
  for ( var c = 0; c <  _story.length; c++ ){
    var pos = new DataPositioner( c );
    renderContainer( storyContentDiv, _story[c]["container"], pos );
  }
}

function renderContainer( div, data, pos )
{
  log( "rendering container of length: " + data.length );
  
  var container = $("<p/>");
  container[0].id = "container_" + pos.getContainerIndex();
  
  div.append( container );
  
  for ( var  i = 0; i < data.length; i++ ){
    var el = data[i];
    if ( typeof( el ) == "object" ){ // changepoint
      var c = renderChangepoint( el, pos.cloneWithIndex( i ) );
    } else {
      var c = renderText( el, pos.cloneWithIndex( i ) );
    }
    c["val"] = c[0].className;
    container.append( c );
  }
}

var _undimTimeout;
var _nodeCount = 0;

function renderChangepoint( el, pos )
{
  var cpIndex = _changePoints.length; 
  _changePoints.push( el ); 
  
  
  var p = $("<span/>");
  p[0].id = "changepoint_" + pos.getContainerIndex() + "_" + pos.getDataIndex();
  el["view"] = p;
  p[0]["containerIndex"] = null;
  p[0]["dataIndex"] = cpIndex;
  p.addClass( "changePoint" );
  var t = document.createTextNode( el['text'] );
  p.append( t );
  p.id = "cp_" + _nodeCount++;

  p.bind( "mouseover", function(){
    p.removeClass("changePoint_dimmed changePoint").addClass( "changePointHover" );
    
    if ( _undimTimeout ){
      clearTimeout( _undimTimeout ); 
      _undimTimeout = null;
    } else {
      dimTheRest( p );
    }
  });
  p.bind( "mouseout", function(){
    setTimeout("unhighlightSelf('" + p.id + "')", 1000 );
    _undimTimeout = setTimeout( "undimAll( )", 3000 );
  });
  
  p.bind( "click", function(){
    processChangePointClick( p[0] );
  });
  
  return p;
}


function renderText( el, pos )
{
  var p = $("<span/>");
  p[0].id = "text_" + pos.getContainerIndex() + "_" + pos.getDataIndex();
  p.addClass( "plainText" );
  p[0]["positioner"] = pos;
  var t = document.createTextNode( el );
  p.append( t );
  p.bind( "mouseup", function(){
    log(" span is up ");
  });
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
  var obj = el[0];
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
  result["width"]  = el[0].offsetWidth;
  result["height"] = el[0].offsetHeight;
  return result;
  
}


function unhighlightSelf( id ){
    log("unhighlight: " + id );
    domEl = $("#" + id);
    domEl.removeClass("changePointHover").addClass( "changePoint_dimmed" );
}

function dimTheRest( domEl ){
  var parent = $("#btContent");
  
  $("span.changePoint").removeClass("changePoint").addClass("changePoint_dimmed");
  $("span.plainText").removeClass("plainText").addClass("plainText_dimmed");  
  
  /*
  for ( var c = 0; c < parent.children().length; c++ ){
    var container = $(parent.children()[c]);  
    for ( var i = 0; i < container.children().length; i ++ ){    
      var child = container.children()[i];
      if ( child != domEl ){
        child.className = child.className + "_dimmed";
      }
    }
  }
  */
}

function undimTheRest( domEl ){
  _undimTimeout = null;
  
  $("span.changePoint_dimmed").removeClass("changePoint_dimmed").addClass("changePoint");
  $("span.plainText_dimmed").removeClass("plainText_dimmed").addClass("plainText");
}

function undimAll(){
  _undimTimeout = null;
  
  $("span.changePointHover").removeClass("changePointHover").addClass("changePoint");
  $("span.changePoint_dimmed").removeClass("changePoint_dimmed").addClass("changePoint");
  $("span.plainText_dimmed").removeClass("plainText_dimmed").addClass("plainText");
}


function beginChangepointEdit( changepoint )
{
  placeVeilOverlay();
  placeControlsOverlay();
  
  pile = getPileFor( changepoint )
  
  var i = 1;
  for ( var id in pile["elements"] ){
    var ui = $("#selectionBox_" + i );
    if ( id == changepoint["pileElement"] ){
      log("default pile element: " + id );
      continue;
    }
    renderTextIn( $("#selectionBoxText_" + i ), pile["elements"][id]["text"] );
    //setupElementSelection( ui, changepoint, pile, id );
    var clickHandler = new ChangePointSelectionEventHandler( ui, changepoint, pile, id );
    ui[0].addEventListener( "click", clickHandler, false);
    _changePointSelectionHelper.registerSelectionHandler( ui, clickHandler );
    i++;
    if ( i > 4 ){
      log("**********  REACHED THE 4 CHOICE LIMITATION  **************");
      break;
    }
  }
  
  while ( i <= 4 ){
    renderTextIn( $("#selectionBoxText_" + i ), "" );
    i++;
  }
    
  var defaultButton = $("#highlightDisplay");
  renderTextIn( $("#selectedElementDisplay"), changepoint["text"] );
  var clickHandler = new ChangePointSelectionEventHandler( defaultButton, changepoint, pile, changepoint["pileElement"] );
  defaultButton[0].addEventListener( "click", clickHandler, false );
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
        var domEl = $( "#" + id );
        domEl.unbind("click");
        //domEl[0].removeEventListener( "click", listener, false );
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
  
  //log(" pile: " + Object.toJSON( pile ) );
  return pile;
}


/**
  *  Fired when a key press is detected in the text area.
  */
function onKeyboardDown( event )
{
  disallowedOp = false;
  selection = getSelectedText();
  
  log( event.keyCode );
  
  var startContainer = selection.anchorNode.parentNode;
  
  if ( startContainer["dataArray"] == null && (event.keyCode < 37 || event.keyCode > 40) ){
    //disallowedOp = true;
    if( event.keyCode == 13 ){
     // beginChangepointEdit( _changePoints[ startContainer["dataIndex"]] );
    }
  }
  
  
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
  
  if ( path.length > 1 || disallowedOp){
    log(" preventing edit of the area");
    event.cancelBubble = true;
    event.returnValue = false; 
    event.preventDefault = true;
    notify("We Are Sorry. Editing of ChangePoints is not alloweds.  Plese modify each Change Point and Text Section individually.");
  }
}

function notify( text )
{
  // TODO: render a notification area somewhere
}

function onKeyboardUp( event )
{ 
   var normal = true;
   switch (event.keyCode){
   /*
     case 8:  // backspace
        handled = true;
        doDelete();
        break;
    */    
     default:
        handled = handleEdit();
        
        break;
   }
   if ( !normal ){
      event.cancelBubble = true;
      event.returnValue = false;   
   }
}

function handleEdit()
{
  selection = getSelectedText();
  
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
    return false;
  }
  
  // WE ARE IN BUSINESS!!!   *************** 
  
  var container      = startContainer["dataArray"];
  var containerIndex = startContainer["dataIndex"];
  
  //log( "modifying element: " + containerIndex + " in array: " + container );
  
  var startOffset = selection.anchorOffset;
  var endOffset   = selection.focusOffset;
  
  log( " start offset: " + startOffset + " end offset: " + endOffset );
  var original = container[containerIndex];
  
  var updatedValue = selection.focusNode.nodeValue;
  log("new value: " + updatedValue );
  
  container[containerIndex] = updatedValue;
  
}


function renderTextIn( para, text )
{
  log(" Rendering text [" + text + "] in " + para );
  while ( para[0].firstChild ){
    para[0].removeChild( para[0].firstChild );
  }
  para.append( document.createTextNode( text ) );
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
  
  log( " start offset: " + startOffset + " end offset: " + endOffset );
  
  
  var original = container[containerIndex];
  
  var data = [];
  data.push( original.substring( 0, startOffset ) );
  data.push( original.substring( startOffset, endOffset) );
  data.push( original.substring( endOffset ) );
  
  //log( "split the original into: " + Object.toJSON( data ) ); 
  
  var pileElement    = _modelFactory.createPileElement( data[1] );
  var pile           = _modelFactory.createPile( pileElement );
  var changePoint    = _modelFactory.createChangepoint( pile, pileElement );
  
  //log( "created pile: " + Object.toJSON( pile ));
  
  //log( "created changepoint: " + Object.toJSON( changePoint ) );
  
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
  var controls = $("#textControlsOverlay");
  
//  controls.css( "display", "inline");
  controls.fadeIn( 200 );
  var textOverlayCoord = calculateAbsoluteCoords( controls );
  var editorCoord      = calculateAbsoluteCoords( $("#btContent") );
  
  //log(" controls coord: " + Object.toJSON( textOverlayCoord ) );
  //log(" editor coord: " + Object.toJSON( editorCoord ) );
  
  var desiredLeft = ( editorCoord["width"]  - textOverlayCoord["width"]  ) / 2 + editorCoord["left"];
  var desiredTop  = ( editorCoord["height"] - textOverlayCoord["height"] ) / 2 + editorCoord["top"] ;
  
  controls.css("left", desiredLeft + "px");
  controls.css("top",  desiredTop  + "px");
}

function removeControlsOverlay()
{
  //$("#textControlsOverlay").css("display", "none");
  $("#textControlsOverlay").fadeOut( 200 );
}

function placeVeilOverlay()
{
  var veil = $("#veil");
  veil.css( "display", "inline");
  
  var coord = calculateAbsoluteCoords( $("#btContent") );
  
  for ( var d in coord ){
    veil.css( d, coord[ d ] + "px");
  }
}

function removeVeilOverlay()
{
  $("#veil").fadeOut( 200 );
  //$("#veil").css("display", "none");
  
  
  
}

function log( msg )
{
  if ( typeof ( console ) != "undefined" ){
    console.log( msg );
  }
  

}

$(document).ready(function(){
  $("#veil").click( function(){
    removeVeilOverlay();
    removeControlsOverlay();
  });
});


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

