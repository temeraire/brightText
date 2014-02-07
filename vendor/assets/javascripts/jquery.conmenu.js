/**
 * @author corey aufang
 * @version 1.0.1
 */
(function($) {
  
  $.conmenu = function(selector, options){
    for ( var i in options ){
      items.push(options[i]);
    }
    $(selector).bind(window.opera?'click':'contextmenu',showmenu);
  };
  
  //defaults
  $.conmenu.containerType = 'div';
  $.conmenu.choicesType = 'div';
  
  var items = [];
  var container = document.createElement($.conmenu.containerType);
  
  $(document).ready(function(){
    $(container).hide().attr('id','conmenu').css('position','absolute').appendTo(document.body);
  });
  
  function showmenu(event){
    event.stopPropagation();
    resetMenu();
		if (window.opera && !event.ctrlKey) {
      return;
    }
    else{
      $(document.body).mousedown(function(){
        resetMenu();
      });
    }
    $.each(items,function(){
      if($.inArray(event.target, $(this.selector)) > -1){
        $.each(this.choices,function(){
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
      }
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

