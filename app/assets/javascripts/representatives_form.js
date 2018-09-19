$(function () {
  function collectPhones() {
    var phone_numbers = '';
    $("#phones_block div.phone-row").each(function (){
      var phone_type = $(this).find(".phone-type").val();
      var phone = $(this).find(".phone").val().trim();
      if(phone != ""){
        phone_numbers += phone_type + phone + ","
      }
    });
    $("#representative_phones_csv").val(phone_numbers);
  }

  function phone_mask(){
    $("div.phone-row .phone").each(function (){
      $(this).inputmask("mask", {"mask": "(999)-999-9999 [x99999]"});
    });
  }

  $("#phones_add").on("click", function(){
    var phone_types_example = $("#phones_block .phone-types-example")[0];
    var phone_row = "<div class='input-group phone-row'><span class='input-group-addon' style='background-color: #43B51F; border: 1px solid #43B51F;'><i class='fa fa-phone'></i></span>"
    + phone_types_example.innerHTML
    + "<input type='text' class='form-control phone' placeholder='Phone Number'/><span class='input-group-btn'><a href='javascript://' class='btn btn-default delete-link' title='Delete'><i class='fa fa-times'></i></a></span></div>";
    $("#phones_block").append(phone_row);
    phone_mask();
  });

  $(document).on("click", ".delete-link", function(){
    $(this).parent().parent().remove();
  });

  $(".select2").select2({allowClear: true});

  $( document ).ready(function() {
    if ($("#representative_phones_csv").val() == "") {
      $("#phones_add").trigger("click");
    }
    collectPhones();
    phone_mask();

    if (isForm('representative', true, false)) {
        $('.new_representative, .edit_representative').submit(function (e) {
            window.onbeforeunload = '';
            collectPhones();
        });
    }

    $("#representative_fax").inputmask();
  });
});
