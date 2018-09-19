$(function(){
	$('#client_industry_id').on('change', function(){
		url = $('#client_industry_id').data('industry-association-with-donors-path')
		industry_id = $(this).val()
		console.log(url)
		$( "#association_to_donors" ).load( url + '?' + $.param({industry_id: industry_id}), function() {

		});
	})
})
