$(function(){
	var generator_input = $('#password_generator');

	$('#btn_generate').on('click',function(e){
		e.preventDefault();

		$.getJSON('/google_accounts/generate_password',function(data){
			generator_input.val(data.password)
		})
	})

	$('.clipboard-link').on('click',function(e){
		e.preventDefault();
	}).clipboard({
		setCSSEffects:true,
		copy: function() {
            var this_sel = $(this);

            // Hide "Copy" and show "Copied, copy again?" message in link
            this_sel.find('.code-copy-first').hide();
            this_sel.find('.code-copy-done').show();

            // Return text in closest element (useful when you have multiple boxes that can be copied)
            return  generator_input.val();
        }
	})
})
