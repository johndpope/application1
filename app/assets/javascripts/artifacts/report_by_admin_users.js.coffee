window.artifacts_images_report_by_admin_users =->
  $('#days_ago').select2
    placeholder: 'Choose',
    width: '100%',
    allowClear: false

  $('#days_ago').on 'change', ->
    document.body.style.cursor='wait'
    days_ago = $(this).val()
    $.get "/artifacts/images/report_by_admin_users.js?days_ago=#{days_ago}"
