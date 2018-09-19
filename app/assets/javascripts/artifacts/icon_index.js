window.artifacts_icon_index = function(){
  var path
  $('body').on('click','.dialog', function(){
    path = $(this).data("path");
    secure = $(this).parent(".box").parent(".row").data("secure");
  });

  var selected_country_id = $('#country_default').data('id');
  var selected_country_name = $('#country_default').data('name');

  function modal_init(){
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
        var data = {id: selected_country_id, text: selected_country_name}
        callback(data);
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
        data: function (term, page) {
          return {
            name_or_code_cont: term,
            level_eq: 1,
            country_id_eq: $('#country').val(),
            page: page,
            per_page: 10,
            sorts: 'name asc'
          }
        },
        results: function (data, page){
          return {
            results: $.map(
              data.items,
              function(e){
                return { id: e.id, text: e.name }
              }
            )
          }
        }
      },
      initSelection: function(element,callback){
        var data = {id: selected_country_id, text: selected_country_name}
        callback(data);
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
            results: $.map(
              data.items,
              function(e){
                return { id: e.id, text: e.name }
              }
            )
          }
        }
      },
      initSelection: function(element,callback){
        var data = {id: selected_country_id, text: selected_country_name}
        callback(data);
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
            results: $.map(
              data.items,
              function(e){
                return { id: e.id, text: e.name }
              }
            )
          }
        }
      },
      initSelection: function(element,callback){
        var data = {id: selected_country_id, text: selected_country_name}
        callback(data);
      }
    });

    $('#industry_id').select2({
      dropdownCssClass: 'bigdrop',
      placeholder: 'Select industry',
      allowClear: true,
      ajax: {
        url: '/industries/tools/json_list',
        dataType: 'json',
        data: function (term, page) {
          return {
            id: $(this).val(),
            q: term
          }
        },
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
    });

    $('#icon_tags').tagsinput({
      tagClass: "label label-success"
    });

    $('#client_id').select2({
      placeholder: 'Choose',
      width: '100%',
      allowClear: true
    });
  }

  $('body').on('shown.bs.modal','#artifacts_icon_image_modal',function(){
    $('#icon_url').val(path);
    modal_init();
  });

  $('body').on('click', '.button_apply_settings', function(){
    $('#icon_settings').submit();
  });

  $('body').on('click', '.cancel_icon', function(e){
    $.ajax({
      url: "/artifacts/icons/delete",
      type: 'DELETE',
      data: {image_path: ""},
      success: function(data){
        $('#selected_icon').html("");
        $('#blended_icon').html("");
        $('#color_fields').html("");
      },
      error: function(e){
        console.log("error");
      }
    });
  });

  $("body").on("click", "#save", function(){
    data = {
      country: $('#country').val(),
      region1: $('#region1').val(),
      region2: $('#region2').val(),
      city: $('#city').val(),
      title: $("#icon_title").val(),
      tag_list: $("#icon_tags").val(),
      notes: $("#icon_notes").val(),
      client_id: $("#client_id").val(),
      industry_id: $("#industry_id").val(),
      icon_temp_file_path: $('#icon_url').val()
    }
    $.ajax({
      url: '/artifacts/icons/save',
      method: "POST",
      data: {data: data}
    }).done(function(){
      $(".row[data-secure='" + secure + "']").hide();
    }).fail(function(error){
      console.log("error");
      $(".row[data-secure='" + secure + "']").css("border","1px solid red");
    });

  });

}
