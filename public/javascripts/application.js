// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
    // increase the default animation speed to exaggerate the effect
$(document).ready(function() {
	var table =$(".sortable_header");//.stupidtable();
	table.bind('aftertablesort', function (event, data) {
		var th = $(this).find("th");
	    th.find(".arrow").remove();
	    var arrow = data.direction === "asc" ? "&uarr;" : "&darr;";
	    th.eq(data.column).append('<span class="arrow">' + arrow +'</span>');
	});
});