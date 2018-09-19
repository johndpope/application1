$(".blending_pattern_modal .todo-list").sortable({
  placeholder: "sort-highlight",
  handle: ".handle",
  forcePlaceholderSize: true,
  zIndex: 999999,
	update: function( event, ui ) {build_pattern_value();}
}).disableSelection();

$(".blending_pattern_modal").on("click", ".btn-delete-blending-pattern-item", function(){
	$(this).closest("li").remove();
	build_pattern_value();
})

function build_pattern_value(){
	$('[name = "blending_pattern[value]"]').val($('ul#blending_pattern_items .blending-pattern-select').map(function(i,e){return e.value}).toArray().join(","));
	console.log($('[name = "blending_pattern[value]"]').val());
}

$(".blending_pattern_modal").on("change",".blending-pattern-select", function(){
	build_pattern_value();
})
