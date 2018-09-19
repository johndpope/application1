window.admin_sandbox_youtube_channel_index = function(){

  $(window).on('show.bs.modal', function(){
    var selectors = [
      '#sandbox_youtube_channel_title_subject_components_csv',
      '#sandbox_youtube_channel_title_entity_components_csv',
      '#sandbox_youtube_channel_title_descriptor_components_csv'
    ].join(', ');

    $(selectors).select2({
      multiple: true,
      data: [],
      width: '100%',
      createSearchChoice: function (term, data) { return { id: term, text: term }; },
      initSelection: function (element, callback) {
        var values = $.map($(element).val().split(/\s*,\s*/), function (v) {
          return { id: v, text: v };
        });
        callback(values);
      }
    });

    $('#sandbox_youtube_channel_sandbox_client_id').select2({
      width: '100%',
      allowClear: true,
      placeholder: "Choose ..."
    });

    $(selectors).each(function(){
      var target_id = $(this).attr("id");
      $("#" + target_id + "_count").text($(this).val().split(",").filter(Boolean).length);
    });

    $(selectors).on('change', function(){
      var target_id = $(this).attr("id");
      $("#" + target_id + "_count").text($(this).val().split(",").filter(Boolean).length);
    });

    $(".tags-field").tagsinput();

    var tag_count = $('#sandbox_youtube_channel_tags').val().split(',').length - 1;
    $('#sandbox_youtube_channel_tag_list_count').text(tag_count);
    $('#sandbox_youtube_channel_tags').on('change', function(){
      $('#sandbox_youtube_channel_tag_list_count').text($(this).val().split(",").filter(Boolean).length);
    });

    var description_items = ['client','industry','location','other'];
    $.each(description_items, function(i,v){
      var target_el = $('body').find('.' + v + '_short_description');
      target_el.each(function(index, element){

        var ln = $(element).val().length;
        $(element).closest('.' + v + '_short_description_block').find('.' + v + '_short_description_count').text(ln);

        $(element).on('keyup', function(e){
          var kl = $(element).val().length;
          $(element).closest('.' + v + '_short_description_block').find('.' + v + '_short_description_count').text(kl);
        });
      });
    });

    $('.remove_btn').on('click', function(){
      $(this).closest('.form-group').remove();
    });

    $('.clear_btn').on('click', function(){
      $(this).closest('.form-group').find('textarea').val("");
    });

    $('body').find('.client_short_description').on('keyup', function(e){
      $(this).closest('.client_short_description_block').find('.badge').text($(this).val().length);
    });

    $('body').find('.delete-link').on('click', function(){ $(this).closest('.description_row').remove(); });


    $('#country').select2({
      placeholder: 'Choose country',
      width: '100%',
      minimumInputLength: 0,
      allowClear: true,
      ajax: {
        url: '/geobase/countries.json',
        quietMillis: 300,
        data: function (term, page) { return { name_or_code_cont: term, page: page, per_page: 10, sorts: 'name asc' } },
        results: function (data, page){
          return {
            results: $.map(
              data.items,
              function(e){
                return { id: e.id, text: e.name }
              }
            ),
            more: (page * 10) < data.total
          }
        }
      },
      initSelection: function(element,callback){
        var data = {id: element.id, text: element.data('name')}
        callback(data);
        $('#sandbox_youtube_channel_location_type').val('Geobase::Country');
        $('#sandbox_youtube_channel_location_id').val(element.attr('value'));
      }
    }).on("change", function(e){
      $('#region1, #region2, #city').select2('val',"");
      if ($('#country').val() != ''){
        $('#sandbox_youtube_channel_location_type').val('Geobase::Country');
        $('#sandbox_youtube_channel_location_id').val($('#country').val());
      }else{
        $('#sandbox_youtube_channel_location_type, #sandbox_youtube_channel_location_id').val('');
      }
    });

    $('#region1').select2({
      placeholder: 'Choose state',
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
    }).on("change", function(e){
      $('#region2, #city').select2('val',"");
      if($('#region1').val() != ''){
        $('#sandbox_youtube_channel_location_type').val('Geobase::Region');
        $('#sandbox_youtube_channel_location_id').val($('#region1').val());
      }else if($('#country').val() != ''){
        $('#sandbox_youtube_channel_location_type').val('Geobase::Country');
        $('#sandbox_youtube_channel_location_id').val($('#country').val());
      }else{
        $('#sandbox_youtube_channel_location_type, #sandbox_youtube_channel_location_id').val('');
      }
    });


    $('#region2').select2({
      placeholder: 'Choose county',
      width: '100%',
      minimumInputLength: 0,
      allowClear: true,
      ajax: {
        url: '/geobase/regions.json',
        quietMillis: 300,
        data: function (term, page) {
          return {
            name_or_code_cont: term,
            level_eq: 2,
            country_id_eq: $('#country').val(),
            parent_id_eq: $('#region1').val(),
            page: page,
            per_page: 10,
            sorts: 'name asc'
          }
        },
        results: function (data, page){
          return {
            results: $.map(data.items, function(e){
              return {
                id: e.id,
                text: e.name
              };
            }),
            more: (page * 10) < data.total
          };
        }
      },
      initSelection: function(element,callback){
        var data = {id: selected_country_id, text: selected_country_name}
        callback(data);
      }
    }).on("change", function(e){
      $('#city').select2('val',"");

      if($('#region2').val() != ''){
        $('#sandbox_youtube_channel_location_type').val('Geobase::Region');
        $('#sandbox_youtube_channel_location_id').val($('#region2').val());
      }else if($('#region1').val() != ''){
        $('#sandbox_youtube_channel_location_type').val('Geobase::Region');
        $('#sandbox_youtube_channel_location_id').val($('#region1').val());
      }else if($('#country').val() != ''){
        $('#sandbox_youtube_channel_location_type').val('Geobase::Country');
        $('#sandbox_youtube_channel_location_id').val($('#country').val());
      }else{
        $('#sandbox_youtube_channel_location_type, #sandbox_youtube_channel_location_id').val('');
      }
    });



    $('#city').select2({
      placeholder: 'Choose city',
      width: '100%',
      minimumInputLength: 0,
      allowClear: true,
      ajax: {
        url: '/geobase/localities.json',
        quietMillis: 300,
        data: function (term, page) {
          return {
            name_or_code_cont: term,
            country_id_eq: $('#country').val(),
            primary_region_id_eq: $('#region1').val(),
            page: page,
            per_page: 10,
            sorts: ['population desc', 'name asc']
          }
        },
        results: function (data, page){
          return {
            results: $.map(data.items, function(e){
                return {
                  id: e.id,
                  text: e.name
                };
              }),
              more: (page * 10) < data.total
          };
        }
      },
      initSelection: function(element,callback){
        var data = {id: selected_country_id, text: selected_country_name}
        callback(data);
      }
    }).on("change", function(e){
      if(locality_id = $(this).val()){
        $.get("/geobase/localities.json?id_eq=" + locality_id + "", function(data){
          var locality = data.items[0];
          var country = locality.country;
          var region1 = locality.primary_region;
          var region2 = locality.secondary_regions[0];
          $('#country').select2('data', { id: country.id, text: country.name });
          $('#region1').select2('data', { id: region1.id, text: region1.name });
          $('#region2').select2('data', { id: region2.id, text: region2.name });
        });
      }

      if($('#city').val() != ''){
        $('#sandbox_youtube_channel_location_type').val('Geobase::Locality');
        $('#sandbox_youtube_channel_location_id').val($('#city').val());
      }else{
        $('#sandbox_youtube_channel_location_type').val('Geobase::Region');
        $('#sandbox_youtube_channel_location_id').val($('#region2').val());
      }
    });


    if(location_json = $('#location_json').val()){
      var json = JSON.parse(location_json)
      if(json.country.name && json.country.id){
        $('#country').select2('data', { id: json.country.id, text: json.country.name });
      }
      if(json.region1.name && json.region1.id){
        $('#region1').select2('data', { id: json.region1.id, text: json.region1.name });
      }
      if(json.region2.name && json.region2.id){
        $('#region2').select2('data', { id: json.region2.id, text: json.region2.name });
      }
      if(json.locality.name && json.locality.id){
        $('#city').select2('data', { id: json.locality.id, text: json.locality.name });
      }
    }

    if($('#city').val() != ''){
      $('#sandbox_youtube_channel_location_type').val('Geobase::Locality');
      $('#sandbox_youtube_channel_location_id').val($('#city').val());
    }else if($('#region2').val() != ''){
      $('#sandbox_youtube_channel_location_type').val('Geobase::Region');
      $('#sandbox_youtube_channel_location_id').val($('#region2').val());
    }else if($('#region1').val() != ''){
      $('#sandbox_youtube_channel_location_type').val('Geobase::Region');
      $('#sandbox_youtube_channel_location_id').val($('#region1').val());
    }else if($('#country').val() != ''){
      $('#sandbox_youtube_channel_location_type').val('Geobase::Country');
      $('#sandbox_youtube_channel_location_id').val($('#country').val());
    }

  });
}
