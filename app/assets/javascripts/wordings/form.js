//= require lib/jquery.json.min.js

function insertErrorAlert (text) {
	p = $('#main');

	$('html, body').animate({ scrollTop: 0 }, 'slow');

	p.find('> .alert.alert-danger.alert-dismissible').each(function (i, e) {
		$(e).remove();
	});

	p.prepend('<div class="alert alert-danger alert-dismissible"><button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' + text + '</div>');
}

function fCheck (where, what) {
	return $.trim(where.find(what).val());
}

function nameAutoComplete () {
	// Array for input name (autocomplete - jQuery UI)
	$('.input-name').autocomplete({ source: $('#name_list').val().split('<sep/>') });
}

function resource_template (resource) {
	$('.animationload').show();

	$.ajax({
		url: '/wordings/resource_template',
		type: 'POST',
		data: resource,
		success: function (response) {
			$('#select2_boxes').removeClass('dn').html(response);
			$('select').select2();
      if ($('input#industry_id').length > 0) {
        $('#industry_id').select2({
          dropdownCssClass: 'bigdrop',
          placeholder: 'Select industry by NAICS industry code or by typing industry name',
          allowClear: true,
          ajax: {
            url: '/industries/tools/json_list',
            dataType: 'json',
            data: function (term, page) { return { id: $(this).val(), q: term } },
            results: function (data, page) { return { results: data } }
          },
          initSelection: function (item, callback) {
            var id = item.val();
            if (id !== '') {
              $.ajax('/industries/tools/json_list', {
                data: { id: id },
                dataType: 'json'
              }).done(function (data) {
                callback(data[0]);
              });
            }
          },
          formatResult: function (item) { return (item.text); },
          formatSelection: function (item) { return (item.text); },
          escapeMarkup: function (m) { return m; }
        }).on("click", function () {
          $(this).select2("open");
        });

        $('#industry_id').on('change', function(){
          $('#wording_resource_type, #wording_resource_id').val('');

      		o = { template: $('input[type="radio"][name="select-type"]:checked').val() }
      		//id_name = $(this).attr('id');
          o.industry_id = $(this).val();
          o.resource_id = $(this).val();
          o.resource_type = 'Industry';
          resource_template(o);
        });

        if (resource.industry_id) $('#industry_id').select2('val', resource.industry_id);
        if ($('.tagsinput').length > 0) {
          $('#wording_industry_tag_list').tagsinput({ tagClass: 'tag label label-tags label-primary' });
          function countKeywords(){
            tag_list_count = 0;
            var tag_list_block = $("#wording_industry_tag_list_block");
            var tag_list_block_input = $("#wording_industry_tag_list_block .bootstrap-tagsinput");
            var tag_list = $("#wording_industry_tag_list").val();
            var tag_list_array = tag_list.split(",").filter(Boolean);
            tag_list_count = tag_list_array.length;
            $("#wording_industry_tag_list_count").text(tag_list_count);
          }

          $(".bootstrap-tagsinput input").css('width', '');
          $("#wording_industry_tag_list").on("itemAdded", function(){
            countKeywords();
          });
          countKeywords();
        }
      }
		},
		error: function () { $('#select2_boxes').addClass('dn').html(''); }
	}).done(function () {
		$('.animationload').hide();
	});
}

$(function () {
  isForm('wording', true, true);
	$('select').select2({ allowClear: true });
	$('.select2-container').addClass('form-control');

	if ((selected_type = $('input[type="radio"][name="select-type"]:checked')).length > 0) resource_template($('#name_list').data('params'));

	nameAutoComplete();

	// Counter characters
	$('textarea.input-source').each(function () {
		counterCharacters((e = $(this)), e.closest('.form-group').find('.counter-characters .label'));
	});

	$(document).on('keyup', '.input-source', function () {
		element = $(this);
		value = element.val();
		parent = element.parent('.form-group');
		label = parent.find('.counter-characters .label');

		counterCharacters(element, label);

		$.ajax({
			url: '/wordings/duplicates.json',
			type: 'POST',
			dataType: 'json',
			data: { text: value },
			success: function (data) {
				(!(s = (data == null || value == '') ? '' : 'There are coincidence!')) ? parent.removeClass('has-error') : parent.addClass('has-error');

				parent.attr('title', s);
			},
			error: function (data) {
				console.log(data);
			}
		});
	});

	$(document).on('click', '#add_fields', function () {
		$('fieldset.form:last').clone().insertBefore('.actions-btn');

		n = $('fieldset.form:last');
		n.find('.remove-fields').addClass('dib');
		//n.find('.input-name').val('');
		n.find('.input-source').val('');
		n.find('.counter-characters > .label').text(0);

		nameAutoComplete();
	});

	$(document).on('click', '.remove-fields', function () {
		if (confirm('Are you sure you want to remove this entry?')) {
			$(this).parent().parent('fieldset.form').remove();
		} else {
			return false;
		}
	});

	$(document).on('change', 'input[type="radio"][name="select-type"], .select-template', function () {
		$('#wording_resource_type, #wording_resource_id').val('');

		o = { template: $('input[type="radio"][name="select-type"]:checked').val() }
		id_name = $(this).attr('id');

		if ((locality_id = $('#locality_id')).length > 0) o.locality_id = locality_id.val();
		if ((state_id = $('select#state_id')).length > 0) o.state_id = state_id.val();
		if ((county_id = $('select#county_id')).length > 0) o.county_id = county_id.val();

		if ((country_id = $('select#country_id')).length > 0) {
			o.country_id = country_id.val();

			if (id_name == 'country_id') {
				o.state_id = '';
				o.county_id = '';
				o.locality_id = '';
			}
		}

		if ($(this).val() == 'country') {
			$('#wording_resource_id').val(1);
			$('#wording_resource_type').val('Geobase::Country');
		}

    if ((industry_id = $('#industry_id')).length > 0) o.industry_id = industry_id.val();

		resource_template(o);
	});

	$(document).on('change', '[data-insert-resource]', function () {
		e = $(this);
		id = e.val();
		geobase = e.data('insert-resource');

		if (id && geobase) {
			$('#wording_resource_id').val(id);
			$('#wording_resource_type').val(geobase);
		} else {
			$('#wording_resource_id').val('');
			$('#wording_resource_type').val('');
		}
	});

	$(document).on('click', 'a[href="#history"]', function () {
		hResourceID = $('#wording_resource_id').val();
		hResourceType = $('#wording_resource_type').val();

		if (hResourceID && hResourceType) {
			$.ajax({
				url: '/wordings/history',
				type: 'POST',
				dataType: 'html',
				data: {
					resource_id: hResourceID,
					resource_type: hResourceType
				},
				beforeSend: function () { $('.animationload').show(); },
				success: function (re_html) { $('#history_body').html(re_html); }
			});

			$('.animationload').hide();
		} else {
			$('#history_body').html('<div class="alert alert-danger">Make a selection of Country/or State/or County/or Locality/or Landmark/or Industry/etc.) in the Main Tab</div>');
		}
	});

  $(document).on('click', 'a.history-wording-name', function () {
    $("#filter_by_name a.history-wording-name").removeClass("btn-primary").addClass("btn-default");
    $(this).removeClass("btn-default").addClass('btn-primary');
    hResourceID = $('#wording_resource_id').val();
    hResourceType = $('#wording_resource_type').val();
    name = $(this).data("name");
    console.log(name);

    if (hResourceID && hResourceType) {
      $.ajax({
        url: '/wordings/history',
        type: 'POST',
        dataType: 'html',
        data: {
          name: name,
          resource_id: hResourceID,
          resource_type: hResourceType
        },
        beforeSend: function () { $('.animationload').show(); },
        success: function (re_html) { $('#history_body').html(re_html); }
      });

      $('.animationload').hide();
    } else {
      $('#history_body').html('<div class="alert alert-danger">Make a selection of Country/or State/or County/or Locality/or Landmark/or Industry/etc.) in the Main Tab</div>');
    }
  });


	$('#save, #next, #update, #update_and_new').click(function () {
		bt = $(this);
		el = $('#new_wording, .edit_wording');
		action = bt.attr('id')
		is_update = action == 'update' || action == 'update_and_new'

		if (!is_update && $('.has-error').length > 0) return insertErrorAlert('<strong>Error:</strong> there are coincidence!');

		region_attributes = {}
		$('.region-attribute').each(function () { region_attributes[$(this).attr('name')] = $(this).val(); });

		data = {
			region_attributes: region_attributes,
			group: []
		};

		$('.data-input').each(function () {
			e = $(this);
			data[e.attr('name')] = e.val();
		});

		$('fieldset.form').each(function (index, element) {
			e = $(element);

			data.group.push({
				name: fCheck(e, '.input-name'),
				source: fCheck(e, '.input-source')
			});
		});

		console.log(data);

		$.ajax({
			url: (!is_update) ? '/wordings/add_batch.json' : '/wordings/update_batch.json',
			type: 'POST',
			dataType: 'json',
			data: { json_object: $.toJSON(data) },
			beforeSend: function () {
        $('.animationload').show();
				$('#save, #next, #update, #update_and_new').addClass('disabled');
			},
			success: function (response) {
				data_collection = {
					country_id: fCheck(el, '#country_id'),
					state_id: fCheck(el, '#state_id'),
					county_id: fCheck(el, '#county_id'),
					locality_id: fCheck(el, '#locality_id'),
					resource_id: data.resource_id,
					resource_type: data.resource_type,
          industry_tags: data.wording_industry_tag_list,
					template: $('input[type="radio"][name="select-type"]:checked').val()
				}
				data_collection = '/wordings/new?' + jQuery.param(data_collection);
        next_edit = response.url;
				url = (bt.attr('id') == 'next' || bt.attr('id') == 'update_and_new') ? data_collection : next_edit;
				window.onbeforeunload = '';
				window.location.replace(url);
			},
			error: function (r) {
				var text = '';

				for (var key in r.responseJSON.message) {
					text += '<strong>' + key + ':</strong> ' + r.responseJSON.message[key][0] + '<br>';
				}

				insertErrorAlert(text);
        $('.animationload').hide();
				$('#save, #next, #update, #update_and_new').removeClass('disabled');
			}
		});
	});
});
