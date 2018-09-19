$(function() {
  isForm('bot_server', true, true);
  $('select').select2({ allowClear: true });
	$('.select2-container').addClass('form-control');
  $('#bot_server_human_emulation').on('ifChanged', function(e){
    var isChecked = e.currentTarget.checked;
    if (isChecked == true) {
      $('#for_human_emulation').show();
    } else {
      $('#for_human_emulation').hide();
    }
  });
  $('.turn-daily-activity').click(function(){
    if(window.confirm("Are you sure?")){
    } else {
      return false;
    }
  });
  $('.positive-numeric').on('change', function () {
    var value = $(this).val();
    if (value < 0) $(this).val(0);
  });

  var order_by = $('#filter_order');
	var order_type = $('#filter_order_type');
	var th = $('#' + order_by.val() + '-th');

	if (th !== 'undefined') th.addClass('sort_' + order_type.val());

	var filter = $('#filter');
	var filter_settings = $('#filter_settings');

	filter.click(function () {
    var open = false;
    if (!$(this).hasClass("open")) {
      $(this).animate({ 'right': '250px' });
      filter_settings.animate({ 'right': '0' });
      $(this).addClass("open");
      open = true;
    } else {
      $(this).animate({ 'right': '0' });
      filter_settings.animate({ 'right': '-250px' });
      $(this).removeClass("open");
    }

		if (typeof(Storage) != 'undefined') {
			if (open) {
				localStorage.setItem('bot-servers-filter-settings-open', 'true');
			} else {
				localStorage.setItem('bot-servers-filter-settings-open', 'false');
			}
		} else {
			console.log('Sorry, your browser does not support Web Storage...');
		}
	});

	if (typeof(Storage) != 'undefined' && localStorage.getItem('bot-servers-filter-settings-open') == 'true') {
    filter.animate({ 'right': '250px' });
    filter_settings.animate({ 'right': '0' });
    filter.addClass("open");
	}

	$('#bot_servers_table th').on('click', function () {
		if ($(this).hasClass('sort')) {
			var data_field = $(this).attr('data-field');
			if ($(this).hasClass('sort_asc')) {
				$('#bot_servers_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_asc').addClass('sort_desc');
				order_type.select2('val', 'desc');
			} else {
				$('#bot_servers_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_desc').addClass('sort_asc');
				order_type.select2('val', 'asc');
			}
			order_by.select2('val', data_field);
			$('#filters_form').submit();
		}
	});
});
