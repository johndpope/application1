//= require 'jquery_nested_form'
$(function () {
  var order_by = $('#filter_order');
  var order_type = $('#filter_order_type');
  var th = $('#' + order_by.val() + '-th');

  if(th !== 'undefined') th.addClass('sort_' + order_type.val());

  var filter = $('#filter');
  var filter_settings = $('#filter_settings');

  filter.click(function() {
    var open = false;
    if (!$(this).hasClass("open")) {
      $(this).animate({ 'right': '250px' });
      filter_settings.animate({ 'right': '0' });
      $(this).addClass("open");
      open = true;
    } else {
      $(this).animate({ 'right': '0' });
      filter_settings.animate({ 'right': '-250px' });
      $(this).removeClass("open");
    }

    if (typeof(Storage) != "undefined") {
      if (open) {
        localStorage.setItem("industries-filter-settings-open", "true");
      } else {
        localStorage.setItem("industries-filter-settings-open", "false");
      }
    } else {
      console.log("Sorry, your browser does not support Web Storage...");
    }
  });

  if (typeof(Storage) != "undefined" && localStorage.getItem("industries-filter-settings-open") == "true") {
    filter.animate({ 'right': '250px' });
    filter_settings.animate({ 'right': '0' });
    filter.addClass("open");
  }

  $("#industries_table th").on("click", function() {
    if($(this).hasClass("sort")) {
      var data_field = $(this).attr("data-field");
      if ($(this).hasClass("sort_asc")) {
        $("#industries_table th").removeClass("sort_asc").removeClass("sort_desc");
        $(this).removeClass("sort_asc").addClass("sort_desc");
        order_type.select2("val", "desc");
      } else {
        $("#industries_table th").removeClass("sort_asc").removeClass("sort_desc");
        $(this).removeClass("sort_desc").addClass("sort_asc");
        order_type.select2("val", "asc");
      }

      order_by.select2("val", data_field);
      $("#filters_form").submit();
    }
  });

  $('select').select2({ allowClear: true });
  $('.select2-container').addClass('form-control');

  $(document).ready(function () {
    $('.numeric').keypress(function (e) {
      if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) return false;
    });
  });

  $('#id').select2({
    dropdownCssClass: 'bigdrop',
    placeholder: 'Enter NAICS code or name',
    allowClear: true,
    ajax: {
      url: '/industries/tools/json_list',
      dataType: 'json',
      data: function (term, page) { return { id: $(this).val(), q: term} },
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

  $('#id').on('click', function(){
    $(this).select2('open');
  });
});
