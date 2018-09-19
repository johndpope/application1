$(function(){
	$(window).on('beforeunload',function(){
		$('.animationload').show()
	})
	$(window).ready(function(){
		$('.animationload').hide()
	})
})
