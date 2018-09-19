$(function() {
  if (isForm('training_info', true, true)) {
    $('#training_info_group_name').autocomplete({ source: $('#group_name_list').val().split('<sep/>') });
  }
});
