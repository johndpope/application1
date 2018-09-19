$(function() {
  var page = $('body').data('page')
  if ('function' === typeof window[page]) { window[page]() }

  (function($) {
    $.fn.getCursorPosition = function() {
        var input = this.get(0);
        if (!input) return; // No (input) element found
        if (document.selection) {
            // IE
           input.focus();
        }
        return 'selectionStart' in input ? input.selectionStart:'' || Math.abs(document.selection.createRange().moveStart('character', -input.value.length));
     }
  })(jQuery);
})
