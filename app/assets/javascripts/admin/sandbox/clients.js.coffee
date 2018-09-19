window.admin_sandbox_clients_index = ->
  $(window).on 'show.bs.modal', ()->
    $('#search-btn').on "click", (e)->
      $.ajax "/admin/sandbox/clients/search",
        type: 'GET'
        data: {q: $('#q').val(); client_id: $('#sandbox_client_client_id').select2('val')}
        error: (jqXHR, textStatus, errorThrown) ->
          alert "error: #{textStatus}"
        success: (data, textStatus, jqXHR) ->
          console.log("success");

    $('.upload_from_artifacts').on 'click', (e)->
      if ($(this).is(':checked'))
        $(this).closest('.form-group').find('.search_artifacts_images').removeClass('hidden');
        $(this).closest('.control-box').find('.search_local_images').addClass('hidden');
      else
        $(this).closest('.form-group').find('.search_artifacts_images').addClass('hidden');
        $(this).closest('.control-box').find('.search_local_images').removeClass('hidden');

    $('#browse_images').on 'click', '.found-image', (e)->
      image_path = $(this).data('path');
      image_src = $(this).attr('src');
      image_trigger = $(this).closest(".modal-dialog").find("form").data('image-trigger');

      $(".#{image_trigger}_container").find("#sandbox_client_#{image_trigger}_path").val(image_path);
      $(".#{image_trigger}_image").html("<img src='#{image_src}', class='img-thumbnail', alt='No image'>");
