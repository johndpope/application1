//= require 'jquery_nested_form'
var ready = function () {
  $('.select-box').select2({ allowClear: true });
	$('.select2-container').addClass('form-control');

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
				localStorage.setItem('queue-filter-settings-open', 'true');
			} else {
				localStorage.setItem('queue-filter-settings-open', 'false');
			}
		} else {
			console.log('Sorry, your browser does not support Web Storage...');
		}
	});

	//if (typeof(Storage) != 'undefined' && localStorage.getItem('queue-filter-settings-open') == 'true') {
    filter.animate({ 'right': '250px' });
    filter_settings.animate({ 'right': '0' });
    filter.addClass("open");
	//}
  // $('#reschedule_date').datepicker({
  //   format: "mm/dd/yyyy",
  //   minDate: 0
  // });

  $('#reschedule_date').daterangepicker({
    startDate: moment(),
    minDate: moment(),
    timePicker: true,
    timePickerIncrement: 15,
    format: 'MM/DD/YYYY h:mm A',
    singleDatePicker: true
  });

  $('#reschedule_date').on('apply.daterangepicker', function(ev, picker) {
    if ($(this).val() != '') {
      $("#reassign_to_div").show();
      $("#reassign_to_div").effect('highlight', { color: '#00a65a' }, 1000);
    } else {
      $("#reassign_to_div").hide();
    }
  });

  $("#clear_rescheduled").on('click', function () {
    $('#reschedule_date').val('');
    $('#reassign_to_div').hide();
    $('[name="job[reassigned_to]"]').select2("val", $('#current_admin_user_id').val());
  });

  $('.calendar').attr("title", "Click on the date after choosing time to apply changes")

  // $('.hourselect', '.minuteselect', '.ampmselect').on('click', function() {
  //   console.log("asdasdasd");
  //   $('.applyBtn').trigger('click');
  // })

  $('#reschedule_date').keypress(function(e) {
    return false;
  });
  $('#reschedule_date').keydown(function(e) {
    return false;
  });
  // $('.select-box').select2({allowClear: true});
  var offset = new Date().getTimezoneOffset();
  $("#utc_offset").val(offset);
  console.log(offset);
  var date = new Date();
  console.log(date.toString());

  $('#days_ago').select2({
    placeholder: 'Choose',
    allowClear: false
  });

  $('#days_ago').on('change', function() {
    var days_ago = $(this).val();
    var queue_name = $('#queue_name').val();
    document.body.style.cursor = 'wait';
    $.get("/queue/" + queue_name + "/report_by_admin_users.js?days_ago=" + days_ago);
  });

  $('#start_call').on('click', function (){
    $(this).effect('highlight', { color: '#EFFF00' }, 500);
    $(this).addClass('disabled');
    $('#end_call').removeClass('disabled');
    $('#end_call').addClass('blink');
    $('#end_call').show();
    $(this).hide();
    start_time = new Date().getTime();
    $('#start_time').val(start_time.toString());
  });
  $('#end_call').on('click', function (){
    if ($('#start_call').hasClass("disabled")) {
      $(this).effect('highlight', { color: '#EFFF00' }, 500);
      $(this).addClass('disabled');
      $(this).removeClass('blink');
      end_time = new Date().getTime();
      $('#end_time').val(end_time.toString());
    }
  });

$('.page, .next, .first, .prev, .next_page').on('click', function (){
    $('.animationload').show();
  });
}

$(document).ready(ready);
$(document).on('page:load', ready);
