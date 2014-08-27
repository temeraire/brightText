/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
// This goes in application.js
// Using this, the confirmation alerts on Rails 3.1 will be replaced with this behaviour:
// The link text changes to 'Sure?' for 2 seconds. If you click the button again within 2 seconds the action is performed,
// otherwise the text of the link (or button) flips back and nothing happens.
 
$.rails.confirm = function(message, element) 
{ 
    var state = element.data('state');
    var txt = element.text();
    if (!state)
    {
        element.data('state', 'last');
        element.text('Sure?');
        setTimeout(function()
        {
            element.data('state', null);
            element.text(txt);
        }, 2000);
        return false;
    }   
    else
    {
        return true;
    }
};
 
$.rails.allowAction = function(element) 
{
    var message = element.data('confirm'),
        answer = false, callback;
    if (!message) { return true; }
 
    if ($.rails.fire(element, 'confirm')) 
    {
        // le extension.
        answer = $.rails.confirm(message, element);
        callback = $.rails.fire(element, 'confirm:complete', [answer]);
    }
    return answer && callback;
};
 
$.rails.handleLink = function(link) 
{
    if (link.data('remote') !== undefined) 
    {
        $.rails.handleRemote(link);
    } 
    else if (link.data('method')) 
    {
        $.rails.handleMethod(link);
    }
 
    return false;
};


