window.templates_aae_projects_index = ->
  $('#project_type, #id, #name, #is_approved').change ->
    $('#search_filter').submit()

  $('#toggle_aae_project_items').change ->
    $('.toggle-aae-project-item').prop('checked', $(this).is(':checked'))

  $(document).on 'click', '.btn-remove-new-text, .btn-remove-new-image', ->
    $(this).closest('tr').remove()

  $('#reset_search_filter').click ->
    $(':text, select', $(this).closest('form')).val('')

  $('#project_type, #is_approved').select2
    placeholder: "Choose",
    width: '100%',
    minimumInputLength: 0,
    allowClear: true

  $('[data-toggle="popover"]').popover()

  $(".preview-video").each ->
    src = $(this).attr("href");
    content = '<video src="' + src + '" autoplay="true" type="video/mp4" controls="true" style="height: 540px; width: 960px" onloadstart="this.volume=0.35"></video>';
    $(this).fancybox({content: content, minHeight: 540, minWidth: 960});

  $('body').on 'shown.bs.modal','.modal', ()->
    $('[data-toggle="popover"]').popover({
      content: $(this).data('content'),
      title: $(this).data('title'),
      html: true,
      placement: 'top',
      container: '.modal',
      trigger: 'hover'
    });
