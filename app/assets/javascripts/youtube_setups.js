var ready = function () {
	$('.assign-accounts').on('click', function(e) {
		if (confirm('Are you sure?')) {
		} else {
			return false;
		}
	});

	// Counter characters
	$(function () {
		$('.read-characters textarea.form-control').each(function () {
			calc_keyup($(this));
		});
	});

	$(document).on('keyup', '.read-characters textarea.form-control', function () {
		calc_keyup($(this));
	});

  update_overview_urls();

  $('#youtube_setup_email_accounts_setup_id').on('change', function(){
    update_overview_urls();
  });

  $('.tags-overview, .descriptions-overview').on('click', function(){
    $('body').addClass('waiting');
  })
}

$(document).ready(ready);
$(document).on('page:load', ready);

function calc_keyup (text_area) {
	var count = 0;
	parent = text_area.closest('.panel.panel-default');

	parent.find('textarea.form-control').each(function () {
		count += $(this).val().length;
	});

	text_area.parent().find('.calc-one').text(text_area.val().length);
	parent.find('.calc').text(count);
}

function update_overview_urls() {
  client_id = $('#youtube_setup_client_id').val();
  $('.tags-overview, .descriptions-overview').each(function(index) {
    target = $(this).data('target');
    source = $(this).data('source');
    final_url = '/clients/' + client_id + '/youtube_setups/' + source + '?target=' + target + '&email_accounts_setup_id=' + $('#youtube_setup_email_accounts_setup_id').val()
    $(this).attr('href', final_url);
  });
}
