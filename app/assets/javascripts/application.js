// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .
// Loads all Bootstrap javascripts
//= require bootstrap


function paginate(total_number_of_pages, current_page) {
	$("#pagination").paginate({
	  count: total_number_of_pages,
	  start: current_page,
	  display: 12,
	  border: false,
	  text_color: '#79B5E3',
	  background_color: 'none', 
	  text_hover_color: '#2573AF',
	  background_hover_color: 'none', 
	  images: false,
	  mouse: 'press',
		onChange: function(page) {
			window.location.replace($.param.querystring(window.location.href, 'page=' + page));
	  }
	});
}
