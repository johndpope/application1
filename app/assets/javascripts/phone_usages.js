//= require fancybox2

$(function () {
  $(document).ready(function(){
    fancyPopup();
    $(document).on("click",".audio-fancybox",function(e) {
      var target = $(event.target);
      if (target.is("a")) {
        target.children(".fa").removeClass("fa-play").addClass("fa-pause");
      } else if (target.is("i")) {
        target.removeClass("fa-play").addClass("fa-pause");
      }
    });
  });

  function fancyPopup() {
    // Declare some variables.
    var el = "";
    var audioTitle = "";
    var posterPath = "";
    var replacement = "";
    var audioTag = "";
    var fancyBoxId = "";
    var posterPath = "";
    var videoTitle = "";

    // Loop over each video tag.
    $("audio").each(function () {
      // Reset the variables to empty.
      el = "";
      audioTitle = "";
      posterPath = "";
      replacement = "";
      audioTag = "";
      fancyBoxId = "";
      posterPath = "";
      videoTitle = "";
      // Get a reference to the current object.
      el = $(this);
      // Set some values we'll use shortly.
      audioTagId = $(this).attr("id");
      audioTitle = $(this).parent().data("code");
      fancyBoxId = this.id + "_fancyBox";
      audioTag = el.parent().html();      // This gets the current video tag and stores it.
      posterPath = el.attr("poster");
      // Concatenate the linked image that will take the place of the <video> tag.
      replacement = "<a title='" + audioTitle + "' class='btn btn-xs btn-primary audio-fancybox' id='" + fancyBoxId + "' href='javascript:;'><i class='fa fa-play'></i></a>"

      // Replace the parent of the current element with the linked image HTML.
      el.parent().replaceWith(replacement);

      /*
      Now attach a Fancybox to this item and set its attributes.

      This entire function acts as an onClick handler for the object to
      which it's attached (hence the "end click function" comment).
      */
      $("[id=" + fancyBoxId + "]").fancybox(
      {
        'content': audioTag,
        'autoDimensions': true,
        'padding': 5,
        'showCloseButton': true,
        'enableEscapeButton': true,
        'width': 500,
        'height': 45,
        'titlePosition': 'outside',
        'beforeShow': function(){
          this.element.title = audioTitle;
          $("audio").attr("autoplay", "autoplay");
          $("audio").show();
        },
        beforeClose: function () {
          $(".audio-fancybox i.fa").removeClass("fa-pause").addClass("fa-play");
        }
      }); // end click function
    });
  }

	$('#date_from').datepicker({
		defaultDate: '+1w',
		changeMonth: true,
		numberOfMonths: 3,
		onClose: function (selectedDate) {
			$('#date_to').datepicker('option', 'minDate', selectedDate);
		}
	});

	$('#date_to').datepicker({
		defaultDate: '+1w',
		changeMonth: true,
		numberOfMonths: 3,
		onClose: function (selectedDate) {
			$('#date_from').datepicker('option', 'maxDate', selectedDate);
		}
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
				localStorage.setItem('phone-usages-filter-settings-open', 'true');
			} else{
				localStorage.setItem('phone-usages-filter-settings-open', 'false');
			}
		} else {
			console.log('Sorry, your browser does not support Web Storage...');
		}
	});

	if (typeof(Storage) != 'undefined' && localStorage.getItem('phone-usages-filter-settings-open') == 'true') {
    filter.animate({ 'right': '250px' });
    filter_settings.animate({ 'right': '0' });
    filter.addClass("open");
	}

	$('select').select2({ allowClear: true });

	$('#phone_usages_table th').on('click', function () {
		if ($(this).hasClass('sort')) {
			var data_field = $(this).attr('data-field');

			if ($(this).hasClass('sort_asc')) {
				$('#phone_usages_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_asc').addClass('sort_desc');
				order_type.select2('val', 'desc');
			} else {
				$('#phone_usages_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_desc').addClass('sort_asc');
				order_type.select2('val', 'asc');
			}

			order_by.select2('val', data_field);
			$('#filters_form').submit();
		}
	});
});
