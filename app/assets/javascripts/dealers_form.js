$(function () {
  var colors = ["primary"];
  var cities_array = [];
  $('#cities_list li').each(function(){
    cities_array.push($(this).data("id").toString());
  });
  collectCities();
  $('.select2-container').addClass('form-control');
  var selected_country_id = $('#country_default').data('id');
  var selected_country_name = $('#country_default').data('name');

  $('#country').val(selected_country_id);

  $('#country').select2({
    placeholder: 'Choose country',
    width: '100%',
    minimumInputLength: 0,
    allowClear: false,
    ajax: {
      url: '/geobase/countries.json',
      quietMillis: 300,
      data: function(term, page) {
        return {
          name_or_code_cont: term,
          page: page,
          per_page: 10,
          sorts: 'name asc'
        };
      },
      results: function(data, page) {
        return {
          results: $.map(data.items, function(e) {
            return {
              id: e.id,
              text: e.name
            };
          }),
          more: (page * 10) < data.total
        };
      }
    },
    initSelection: function(element, callback) {
      var data;
      data = {
        id: selected_country_id,
        text: selected_country_name
      };
      return callback(data);
    }
  });

  $('#country').prop("disabled", true);

  $('#region1').select2({
    placeholder: 'Filter by state',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true,
    ajax: {
      url: '/geobase/regions.json',
      quietMillis: 300,
      data: function(term, page) {
        return {
          name_or_code_cont: term,
          level_eq: 1,
          country_id_eq: $('#country').val(),
          page: page,
          per_page: 10,
          sorts: 'name asc'
        };
      },
      results: function(data, page) {
        return {
          results: $.map(data.items, function(e) {
            return {
              id: e.id,
              text: e.name
            };
          }),
          more: (page * 10) < data.total
        };
      }
    }
  });

  $('#city').select2({
    placeholder: 'Choose locality',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true,
    ajax: {
      url: '/geobase/localities.json',
      quietMillis: 300,
      data: function(term, page) {
        return {
          name_or_code_cont: term,
          country_id_eq: $('#country').val(),
          primary_region_id_eq: $('#region1').val(),
          page: page,
          per_page: 10,
          sorts: ['population desc', 'name asc']
        };
      },
      results: function(data, page) {
        return {
          results: $.map(data.items, function(e) {
            return {
              id: e.id,
              text: e.name + ', ' + e.primary_region.code.split('<sep/>')[0].replace('US-', '')
            };
          }),
          more: (page * 10) < data.total
        };
      }
    }
  }).on('change', function(){
    if ($(this).val() != '' && $(this).val() != undefined) {
      if ($.inArray($(this).val(), cities_array) === -1) {
        cities_array.push($(this).val());
        collectCities();
        $("#cities_list").append("<li class='col-md-3' data-id='" + $(this).val() +  "'><a href='javascript://'' class='btn btn-default btn-xs delete-city-link' title='Delete'><i class='fa fa-times'></i></a>" + $(this).select2('data').text + "</li>");
        $("#selected_localities_count").effect("highlight", {color: '#79ce7a'}, 3000);
      } else {
        $("#selected_localities_count").effect("highlight", {color: '#ffa700'}, 3000);
      }
      $('#city').select2('val', '');
    }
  });

  $('#region1').on('change', function() {
    $('#region2').select2('val', '');
    $('#city').select2('val', '');
  });

  $(document).on('click', '.delete-city-link', function () {
    console.log("click");
    //if (window.confirm("Are you sure you want to delete this location?")) {
      city_id = $(this).parent().data('id').toString();
      index = cities_array.indexOf(city_id);
      if (index > -1) {
        cities_array.splice(index, 1);
        collectCities();
    		$(this).parent().remove();
      }
    //}
  });

  function collectCities(){
    if (cities_array.length > 0) {
      $('#localities_missing_text').hide();
    } else {
      $('#localities_missing_text').show();
    }
    $('#selected_localities_count').text(cities_array.length);
    $('#dealer_cities').val('{' + cities_array + '}');
  }
  // Counter characters
	function calc_one (text_area) {
		text_area.closest('.form-group').find('.calc-one').text(text_area.val().length);
	}

	$('fieldset textarea').each(function () {
		calc_one($(this));
	});

	$(document).on('keyup', 'fieldset textarea', function () {
		calc_one($(this));
	});

  $(document).on('change', 'fieldset textarea', function () {
		calc_one($(this));
	});

  $(document).on('change', '.description-name-select', function () {
    text_input = $(this).closest('fieldset').find('textarea');
    text_input_limit = $('option:selected', $(this)).attr('data-text-type-limit');
    text_input_value = text_input.val();
    if (text_input_limit != undefined) {
      text_input.val(text_input_value.slice(0,text_input_limit));
      text_input.attr('maxlength', text_input_limit);
      text_input.attr('placeholder', 'Enter text (character limit: ' + text_input_limit + ')');
      text_input.trigger('change');
      if (text_input_value.length > text_input_limit){
        alert("Text string will be truncated!");
        text_input.effect('highlight', { color: 'red' }, 3000);
        text_input.trigger('keyup');
      }
    } else {
      text_input.val('');
      text_input.removeAttr('maxlength');
      text_input.attr('placeholder', 'Enter text');
      text_input.trigger('keyup');
    }
  });

  var availableTags = $('#brands_list').val().split('<sep/>');
  function split( val ) {
    return val.split( /,\s*/ );
  }
  function extractLast( term ) {
    return split( term ).pop();
  }

  function otherBrandsAutoComplete () {
    $("#dealer_other_brands").on( "keydown", function( event ) {
        if ( event.keyCode === $.ui.keyCode.TAB &&
            $( this ).autocomplete( "instance" ).menu.active ) {
          event.preventDefault();
        }
      }).autocomplete({
        minLength: 0,
        source: function( request, response ) {
          // delegate back to autocomplete, but extract the last term
          response( $.ui.autocomplete.filter(
            availableTags, extractLast( request.term ) ) );
        },
        focus: function() {
          // prevent value inserted on focus
          return false;
        },
        select: function( event, ui ) {
          var terms = split( this.value );
          // remove the current input
          terms.pop();
          // add the selected item
          terms.push( ui.item.value );
          // add placeholder to get the comma-and-space at the end
          terms.push( "" );
          unique = terms.filter(function(itm, i, a) {
            return i == terms.indexOf(itm);
          });
          str = unique.join( ", " );
          str = str.substring(0, str.length-2);
          this.value = str;
          return false;
        }
    });
  }
  otherBrandsAutoComplete();
  $('#dealer_other_brands').attr("placeholder", "Other brands (comma separated)");
});
