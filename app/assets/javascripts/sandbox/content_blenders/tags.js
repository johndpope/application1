$(function(){
	function tags() {
		// Color tags
		var attr = ['tb-red', 'tb-gray tb-gray-one', 'tb-black', 'tb-gray tb-gray-two'];
		var atl = attr.length;
		var al = $('.box-content-ah.cvd-tags b').length;

		for (var i = 0, el = 0; el <= al; i++, el++) {
			if (i == atl) i = 0;
			$('.box-content-ah.cvd-tags b:eq(' + el + ')').addClass(attr[i]);
		}
	}

	if ($('.box-content-ah.cvd-tags b').length) tags();
})
