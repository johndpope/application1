//= require fancybox

fancybox_settings = {
  helpers: {
    title : {
      type : 'float'
    }
  }
}

$(function (){
  $(".image-preview").fancybox(fancybox_settings);
  // Counter characters
  function calc_one (text_area) {
    text_area.closest('.form-group').find('.calc-one').text(text_area.val().length);
  }

  function countKeywords(){
    keywords_count = 0;
    var keywords_block = $("#keywords_block");
    var keywords = $("#youtube_video_tags").val();
    if (keywords != ""){
      var keywords_array = $.map(keywords.split(","), $.trim).filter(Boolean).filter(function(item, pos, self) {
        return self.join(',').toLowerCase().split(',').indexOf(item.toLowerCase()) == pos;
      });
      $("#youtube_video_tags").val(keywords_array.join(","));
      keywords_count = keywords_array.length;
    }
    calc_one($("#youtube_video_tags"));
    $("#keywords_label").text("Tags: " + keywords_count);
  }

  $('select').select2();

  $(document).ready(function() {
    $(".select2-container").addClass("form-control");
    countKeywords();

    isForm('youtube_video', true, true);

    $("#youtube_video_source_video_id").select2({
        dropdownCssClass: "bigdrop",
        minimumInputLength: 2,
        placeholder: "Select source video",
        allowClear: true,
        ajax: {
          url: "/source_videos/tools/json_list",
          dataType: 'json',
          data: function(term, page) { return { q: term } },
          results: function(data, page) { return { results: data } }
        },
        initSelection: function (item, callback) {
            var id = item.val();
            if(id !== "") {
                $.ajax("/source_videos/tools/json_list", {
                    data: {id: id},
                    dataType: "json"
                }).done(function(data) {
                    callback(data[0]);
                });
            }
        },
        formatResult: function (item) { return (item.text); },
        formatSelection: function (item) { return (item.text); },
        escapeMarkup: function (m) { return m; }
    });

    $("#youtube_video_youtube_channel_id").select2({
        dropdownCssClass: "bigdrop",
        minimumInputLength: 2,
        placeholder: "Select youtube channel",
        allowClear: true,
        ajax: {
          url: "/youtube_channels/tools/json_list",
          dataType: 'json',
          data: function(term, page) { return { q: term } },
          results: function(data, page) { return { results: data } }
        },
        initSelection: function (item, callback) {
            var id = item.val();
            if(id !== "") {
                $.ajax("/youtube_channels/tools/json_list", {
                    data: {id: id},
                    dataType: "json"
                }).done(function(data) {
                    callback(data[0]);
                });
            }
        },
        formatResult: function (item) { return (item.text); },
        formatSelection: function (item) { return (item.text); },
        escapeMarkup: function (m) { return m; }
    });

    $('.count-characters').each(function () {
      calc_one($(this));
    });

    $(document).on('keyup', '.count-characters', function () {
      calc_one($(this));
    });

    $(document).on('change', 'count-characters', function () {
  		calc_one($(this));
  	});
  });

  $("#youtube_video_tags").on("change", function(){
    countKeywords();
  });
});
