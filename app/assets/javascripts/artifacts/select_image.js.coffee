fancybox_settings = {
  helpers: {
    title : {
      type : 'float'
    }
  }
}
$('#select_image_modal_dialog').on 'click', '.found-image, .logo-image', ->
  image_type = $(this).data("type")
  image_path = $(this).data('path')
  img_trigger= $(this).closest(".modal-dialog").find("form").data('image-trigger')
  image_url = $(this).attr("src")
  image_id = $(this).data('id')

  image_dimension = $(this).siblings('.btn-group').find(".dimensions").text();
  image_href = $(this).siblings('.btn-group').find(".dimensions").attr("href");

  $.ajax "/artifacts/image_blender/image_info/#{image_id}",
    type: 'GET'
    data: {img_trigger: img_trigger}
    error: (jqXHR, textStatus, errorThrown) ->
      alert "Error: #{textStatus}"
    success: (data, textStatus, jqXHR) ->

  $("#image_blender_#{img_trigger}").siblings('.img_dimensions').html("<a class = 'btn btn-default btn-sm' href = '#'><i class = 'fa fa-file-image-o'></i>#{image_dimension}</a>");
  $("#image_blender_#{img_trigger}").val(image_path)
  $("#image_blender_#{img_trigger}").siblings('.img_container').find('img').attr('src',image_url)
  $("#image_blender_#{img_trigger}").siblings('.img_container').find('a').attr('href',image_url.replace("thumb","original"))

  $("#image_blender_#{img_trigger}_id").val(image_id)
  $("#image_blender_#{img_trigger}_type").val(image_id).attr('name', "image_blender[image_type][#{image_type}]")

  $(".preview").each ->
    $(this).fancybox();
