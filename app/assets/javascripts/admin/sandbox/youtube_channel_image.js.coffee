#= require jquery-fileupload
window.admin_sandbox_youtube_channel_image_index =->
  $(window).on 'shown.bs.modal', () ->
    $('#sandbox_youtube_channel_image_sandbox_client_id, #sandbox_youtube_channel_image_image_type').select2
      width: "100%",
      placeholder: "Choose client"

    $('#new_sandbox_youtube_channel_image').fileupload
      autoUpload: false,
      dataType: 'json'
    .on 'fileuploaddone', (e,data) ->
      obj = data.result.files[0];
      $('#sandbox_youtube_channel_image_items .tbody').prepend("
      <tr>
        <td></td>
        <td>#{obj.id}</td>
        <td><a href='/admin/sandbox/youtube_channel_image?q[sandbox_client_id_eq]=#{obj.sandbox_client_id}'>#{obj.client}</a></td>
        <td class='text-center'><a href='#{obj.url}' target='_blank'><img alt='no img' class='img-thumbnail livepreview' data-src='#{obj.path}' src='#{obj.url}' style='width: 60px; height: 40px;'></a></td>
        <td><a href='/admin/sandbox/youtube_channel_image?q[image_type_eq]=#{obj.image_type}'>#{obj.type}</a></td>
        <td>
          <div class='btn-group' role='group'>
            <a class='btn btn-default btn-sm' data-remote='true' data-target='.sandbox_youtube_channel_image' data-toggle='modal' href='/admin/sandbox/youtube_channel_image/#{obj.id}/edit' title='Edit' data-disable-with='<i class='fa fa-refresh fa-spin'></i><i class='fa fa-pencil'></i></a>
            <a class='btn btn-default btn-sm' data-confirm='Are you sure?' data-method='delete' data-remote='true' href='/admin/sandbox/youtube_channel_image/#{obj.id}' rel='nofollow' data-disable-with='<i class='fa fa-refresh fa-spin'></i><i class='fa fa-trash'></i></a>
          </div>
        </td>
      </tr>
      ");
      $('tbody.tbody tr:first td.row_nr', '#sandbox_youtube_channel_image_items').text($('tbody.tbody tr', '#sandbox_youtube_channel_image_items').length);
