var ready = function() {
  $('.numeric').keypress(function (e) {
    if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) return false;
  });

  $('.iCheck-helper').iCheck({
		checkboxClass: 'icheckbox_minimal-blue',
		radioClass: 'iradio_minimal-blue',
		increaseArea: '20%'
	});

	$('body').on('click', '.spoiler a', function() {
		$(this).next().slideToggle();
	});

	$('input[rel=date]').each(function() {
		apply_datepicker($(this));
	});

	$('[data-loading-text]').each(function() {
		$(this).click(function() {
			var element = $(this);
			element.button('loading');
			setTimeout(function() { element.button('reset') }, 3000);
		});
	});

	$('[data-rel=nicescroll]').each(function() {
		$(this).niceScroll({
			cursorcolor: '#cdcdcd',
			autohidemode: false
		});
	});

  $('.alert-fade-out').fadeOut(3000);

	// APPLY DATEPICKER TO THE DYNAMICALLY INSERTED INPUTS
	$('a.add_nested_fields').click(function() {
		// Wait before the elements are inserted
		setTimeout(function() {
			$('input[rel=date]:not(.hasDatepicker').each(function() {
				apply_datepicker($(this));
			});
		}, 25);
	});

	//apply select2
	$('.select2').select2()

	var hash = window.location.hash;
	$('.nav a[href="' + hash + '"]').tab('show');

	if ($('.pagination-endless').length > 0) {
		$(document).scroll(function() {
			var url = $('.pagination a[rel="next"]').attr('href');
			var message = $('.pagination-endless').attr('data-loading-text');
			if (url && $(window).scrollTop() > ($(document).height() - $(window).height() - 50)) {
				$('.pagination').text(message);
				$.getScript(url);
			}
		});
	}

	/*
		Preview for media content
		Image preview script powered by jQuery
	*/
	function imagePreview() {
		// Config
		xOffset = 40;
		yOffset = 60;

		function coordinates(e) {
			var valColBt = $('#preview').bottom;
			var countBottom = (valColBt == 'NaN')? 0 : valColBt;
			var local = new Object();
			local.left = ((e.pageX + yOffset) + 'px');

			if (countBottom <= 0) {
				local.top = 'auto';
				local.bottom = 0;
			} else {
				local.top = ((e.pageY - xOffset) + 'px');
				local.bottom = 'auto';
			}

			// console.log(local);
			return $('#preview').css(local);
		}

		$(document.body).on({
			mouseover: function(e) {
				var parentElement = $(this).closest('li');
				var arraySourceAndTitle = [parentElement.attr('data-source-url'), parentElement.attr('data-title')];
				var previewElements = '<video><source src="' + arraySourceAndTitle[0] + '" type="video/mp4" /></video><h3>' + arraySourceAndTitle[1] + '</h3>';

				$('body').append('<div id="preview">' + previewElements + '</div>');
				coordinates(e).fadeIn('fast');

				if ((player = $('#preview video')).length >= 1) {
					player = player[0];
					player.preload = 'none',
					player.play();
					player.loop = true;
				}
			},
			mouseout: function(e) {
				delete previewElements, player;
				$('#preview').remove();
			}
		}, '.preview');

		$('.preview').mousemove(function(e) {
			coordinates(e);
		});
	}

	imagePreview();
	/*--- end ---*/

	/*--- Timeline delete last plus ---*/
	glyphiconDisplay();

  $('#toolbar-toggle').on('click', function() {
    if (!$(this).hasClass('open')) {
      $(this).animate({ 'right': '250px' });
      $('#toolbar').animate({ 'right': '0' });
      $(this).addClass('open');
    } else {
      $(this).animate({ 'right': '0' });
      $('#toolbar').animate({ 'right': '-250px' });
      $(this).removeClass('open');
    }
  });

  // Has Error?!
	$('.has-error').popover({
		trigger: 'hover',
		placement: 'bottom',
		animation: true
	});

  $('.popover-box').popover({
		trigger: 'hover',
		placement: 'top',
    container: 'body',
		animation: true
	});
}

$(document).ready(ready);
$(document).on('page:load', ready);

function apply_datepicker(element) {
	element.datepicker({
		changeMonth: true,
		changeYear: true,
		dateFormat: 'M d, yy',
		yearRange: '1950:' + new Date().getFullYear()
	});
}

var glyphiconDisplay = function() {
	$('#video_timeline li').each(function(indx, element) {
		$(element).find(' > i.glyphicon').css('display', '');
	});

	$('#video_timeline li:eq(-1) > i.glyphicon').css('display', 'none');
}

function isForm (class_name, doYou, onbefoReunload) {
	if ($('.edit_' + class_name).length > 0 || $('.new_' + class_name).length > 0) {
		if (doYou) DoYouReallyWantToLeaveThisPage();

		if (onbefoReunload) {
			$('.new_' + class_name + ', .edit_' + class_name).submit(function (e) {
				window.onbeforeunload = '';
        $('.animationload').show();
			});
		}

		return true;
	} else {
		return false;
	}
}

function DoYouReallyWantToLeaveThisPage () {
	window.onbeforeunload = function (evt) {
		message = 'Do you really want to leave this page? You may lost unsaved data!';
		if (typeof evt == 'undefined') evt = window.event;
		if (evt) evt.returnValue = message;
    $('.animationload').hide();
		return message;
	}
}
