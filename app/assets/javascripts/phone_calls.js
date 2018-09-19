$(function () {
  $(document).ready(function(){
    jQuery(".best_in_place").best_in_place();
    $('.best_in_place').bind('ajax:success', function (xhr, data, status) {
  		$(this).effect('highlight', { color: '#70CB6A' }, 2000);
  	});
  });
});
