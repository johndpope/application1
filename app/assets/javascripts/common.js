var ready = function () {
  function notifyMe(title, options) {
    // Let's check if the browser supports notifications
    if (!window.Notification) {
      console.log("This browser does not support desktop notification");
      //alert("This browser does not support desktop notification");
      alert(options["body"]);
    } else {
      console.log(Notification.permission.toLowerCase());
      switch ( Notification.permission.toLowerCase() ) {
        case "granted":
            var notification = new Notification(title, options);
            break;
        case "denied":
            alert(options["body"]);
            break;
        case "default":
            Notification.requestPermission();
            alert(options["body"]);
      }
    }
  }

  function spawnNotification(theBody,theIcon,theTitle) {
    var options = {
      body: theBody,
      icon: theIcon
    }
    var n = new Notification(theTitle,options);
  }

  if (window.Notification) {
    if (Notification.permission.toLowerCase() == "default") {
      Notification.requestPermission();
    }
  }

  // Enable pusher logging - don't include this in production
  //Pusher.logToConsole = true;

  var pusher = new Pusher('0e12cf705e3afee69722', {
    cluster: 'eu',
    encrypted: true
  });

  var channel = pusher.subscribe('default_channel');
  channel.bind('deploy_event', function(data) {
    var options = {
      body: data.message,
      icon: '/favicon.ico',
      tag: "deploy"
    }
    notifyMe(data.title, options);
  });

  channel.bind('default_event', function(data) {
    var options = {
      body: data.message,
      icon: '/favicon.ico',
      tag: "default"
    }
    notifyMe(data.title, options);
  });

	if (supports_html5_storage()) {
		var shs_key = 'sidebar';

		if (localStorage.getItem(shs_key) == null) {
			localStorage.setItem(shs_key, 'auto');
		} else {
			shs_value = localStorage.getItem(shs_key);
			makeASmallSitebar(shs_value);
		}

		$('.sidebar-toggle[data-toggle="offcanvas"]').click(function () {
			if (supports_html5_storage()) ($('body').hasClass('sidebar-collapse')) ? localStorage.setItem(shs_key, 'mini') : localStorage.setItem(shs_key, 'normal');
		});
	}

	$('body').on('click', '.spoiler a', function () {
		$(this).next().slideToggle();
	});

	$('.alert-fade-out').fadeOut(10000);

	$('input[rel=date]').each(function () {
		apply_datepicker($(this));
	});

	$('[data-loading-text]').each(function () {
		$(this).click(function () {
			var element = $(this);
			element.button('loading');
			setTimeout(function () { element.button('reset') }, 3000);
		});
	});

	$('[data-rel=nicescroll]').each(function () {
		$(this).niceScroll({
			cursorcolor: '#cdcdcd',
			autohidemode: false
		});
	});

	// APPLY SELECT-2, DATEPICKER TO THE DYNAMICALLY INSERTED INPUTS
	$('a.add_nested_fields').click(function () {
		// Wait before the elements are inserted
		setTimeout(function () {
			$('input[rel=date]:not(.hasDatepicker').each(function () {
				apply_datepicker($(this));
			});
		}, 25);
	});

	var hash = window.location.hash;
	$('.nav a[href="' + hash + '"]').tab('show');

	if ($('.pagination-endless').length > 0) {
		$(document).scroll(function () {
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
			var countBottom = parseFloat($('#preview').css('bottom'));
			var local = new Object();
			local.left = ((e.pageX + yOffset) + 'px');

			if (countBottom <= 0) {
				local.top = 'auto';
				local.bottom = 0;
			} else {
				local.top = ((e.pageY - xOffset) + 'px');
				local.bottom = 'auto';
			}

			return $('#preview').css(local);
		}

		$('.preview').hover(function (e) {
			var previewElements = $(this).find('.preview-elements');

			if (previewElements.length == 0) return false;

			$('body').append('<div id="preview">' + previewElements.html() + '</div>');
			coordinates(e).fadeIn('fast');

			if ((player = $('#preview video')).length >= 1) {
				player = player[0];
				player.preload = 'none',
				player.play();
				player.loop = true;
			}
		},
		function () {
			delete previewElements, player;
			$('#preview').remove();
		});

		$('.preview').mousemove(function (e) {
			coordinates(e);
		});
	}

	imagePreview();
	/*--- end ---*/

	/*--- Timeline delete last plus ---*/
	glyphiconDisplay();

	$('.iCheck-helper').iCheck({
		checkboxClass: 'icheckbox_minimal-blue',
		radioClass: 'iradio_minimal-blue',
		increaseArea: '20%'
	});

	$('.datepicker').datepicker({
		language: 'en',
		changeMonth: true,
		changeYear: true,
		dateFormat: 'mm/dd/yy'
	});

	// Has Error?!
	$('.has-error').popover({
		trigger: 'hover',
		placement: 'bottom',
		animation: true
	});

	// if ($('#inbox').length == 1) {
	// 	$.ajax({
	// 		url: '/sandbox/contact_us/inbox',
	// 		data: { 'list': 'false' },
	// 		type: 'post',
	// 		success: function (col) {
	// 			if (!col <= 0) {
	// 				inbox = $('#inbox');
	// 				inbox.addClass('dropdown messages-menu');
	// 				inbox.find('> a').attr({
	// 					'href': 'javascript://',
	// 					'class': 'dropdown-toggle',
	// 					'data-toggle': 'dropdown',
	// 					'data-load-content': 'true'
	// 				}).append('<span class="label label-success">' + col + '</span>');
	// 				inbox.append('<ul class="dropdown-menu"></ul>');
	// 			}
	// 		},
	// 		error: function (data) {
	// 			console.log(data);
	// 		}
	// 	});
  //
	// 	$(document).on('click', '#inbox > a.dropdown-toggle[data-load-content]', function () {
	// 		$(this).removeAttr('data-load-content');
  //
	// 		$.ajax({
	// 			url: '/sandbox/contact_us/inbox',
	// 			data: { 'list': 'true' },
	// 			type: 'post',
	// 			success: function (partial) {
	// 				$('#inbox .dropdown-menu').html(partial);
	// 			},
	// 			error: function (data) {
	// 				console.log(data);
	// 			}
	// 		});
	// 	});
	// }

  $('#scroll-up').on('click', function(){
    $('html, body').animate({ scrollTop: 0 }, 800);
  });
  $('#scroll-down').on('click', function(){
    $('body, html').animate({ scrollTop: $(document).height() }, 800);
  });

  $('[data-toggle="popover"]').popover({
    content: $(this).data('content'),
    title: $(this).data('title'),
    html: true,
    placement: 'top',
    container: 'body',
    trigger: 'hover'
  });

}

$(document).ready(ready);
$(document).on('page:load', ready);

function supports_html5_storage () {
	try {
		return 'localStorage' in window && window['localStorage'] !== null;
	} catch (e) {
		return false;
	}
}

function makeASmallSitebar (size) {
	if (size == 'auto') {
		if (window.screen.availWidth < 1920) $('body').addClass('sidebar-collapse');
	} else if (size == 'mini') {
		$('body').addClass('sidebar-collapse');
	} else if (size == 'normal') {
		$('body').removeClass('sidebar-collapse');
	}

	$('.sidebar-toggle').effect('highlight', { color: '#367fa9' }, 3000);
}

function apply_datepicker (element) {
	element.datepicker({
		changeMonth: true,
		changeYear: true,
		dateFormat: 'M d, yy',
		yearRange: '1950:' + new Date().getFullYear()
	});
}

var glyphiconDisplay = function () {
	$('#video_timeline li').each(function (indx, element) {
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

// Counter characters
function counterCharacters (input, e) {
	e.text(input.val().length);
}
