var ready = function () {
	$('#btn_remove_logo').on('click', function(){
		$('#product_remove_logo').val('true')
		$(this).closest('#logo_info').remove()
	})

	$('#product_logo').change(function(){
		if($(this).val().length != 0){
			$('#product_remove_logo').val('false')
		}
	})
}

$(document).ready(ready);
$(document).on('page:load', ready);
