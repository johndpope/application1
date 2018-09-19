window.admin_tooltips_index = ->
  val_in = "";
  val_out = "";
  $('textarea')
    .on "focusin", (e) ->
      val_in = e.target.value;
    .on 'focusout', (e)->
      val_out = e.target.value
      if val_in != val_out
        $(this).closest('form').submit();
