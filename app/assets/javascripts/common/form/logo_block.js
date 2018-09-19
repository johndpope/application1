var ready = function () {
	$('[data-role="btn-remove-logo"]').on('click', function(){
		logo_block = $(this).closest('[data-role="logo-block"]')
		$('[data-role="remove-logo-attr-field"]', logo_block).val('true')
		$('[data-role="logo-info"]', logo_block).remove()
	})

	$('[data-role="client-logo"]').change(function(){
		if($(this).val().length != 0){
			$('[data-role="remove-logo-attr-field"]').val('true')
		}
	})
}

$(document).ready(ready);
$(document).on('page:load', ready);
