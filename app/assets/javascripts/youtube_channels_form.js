$(function (){

  // Counter characters
  function calc_one (text_area) {
    text_area.closest('.form-group').find('.calc-one').text(text_area.val().length);
  }

  function countKeywords(){
    keywords_count = 0;
    var keywords_block = $("#keywords_block");
    var keywords = $("#youtube_channel_keywords").val();
    if (keywords != ""){
      var keywords_array = $.map(keywords.split(","), $.trim).filter(Boolean).filter(function(item, pos, self) {
        return self.join(',').toLowerCase().split(',').indexOf(item.toLowerCase()) == pos;
      });
      $("#youtube_channel_keywords").val(keywords_array.join(","));
      keywords_count = keywords_array.length;
    }
    calc_one($("#youtube_channel_keywords"));
    $("#keywords_label").text("Keywords: " + keywords_count);
  }

  function collectLinks(){
    var linksData = {
        links : []
    };

    $("#channel_links_block div").each(function (){
      var link_name = $(this).find(".link-name").val().trim();
      var link_url = $(this).find(".link-url").val().trim();
      if(link_name != "" && link_url != ""){
        linksData.links.push({name: link_name, url: link_url});
      }
    });
    $("#youtube_channel_channel_links").val(JSON.stringify(linksData));
  }

  $("#channel_links_add").on("click", function(){
    var link_row = '<div class="link-row"><input type="text" class="form-control link-name" maxlength="30" placeholder="Link Title"><input type="text" class="form-control link-url" placeholder="Link URL"><a href="javascript://" class="btn btn-default btn-xs delete-link"><i class="fa fa-trash-o"></i></a></div>';
    $("#channel_links_block").append(link_row);
  });

  $(document).on("click", ".delete-link", function(){
    $(this).parent().remove();
  });

  $('select').select2();


  $( document ).ready(function() {
    $("#youtube_channel_category").select2({
      placeholder: "Select category"
    });
    $(".select2-container").addClass("form-control");
    countKeywords();
    collectLinks();

    if (isForm('youtube_channel', true, false)) {
        $('.new_youtube_channel, .edit_youtube_channel').submit(function (e) {
            window.onbeforeunload = '';
            collectLinks();
        });
    }

    $("#youtube_channel_google_account_id").select2({
        dropdownCssClass: "bigdrop",
        minimumInputLength: 2,
        placeholder: "Select email account",
        allowClear: true,
        ajax: {
          url: "/email_accounts/tools/json_list",
          dataType: 'json',
          data: function(term, page) { return { q: term } },
          results: function(data, page) { return { results: data } }
        },
        initSelection: function (item, callback) {
            var id = item.val();
            if(id !== "") {
                $.ajax("/email_accounts/tools/json_list", {
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

    $(document).on('change', '.count-characters', function () {
  		calc_one($(this));
  	});
  });

  $("#youtube_channel_keywords").on("change", function(){
    countKeywords();
  });
});
