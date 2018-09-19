$(function(){		
	var content_wrapper = $('#content_wrapper');
	$('.preview-video-script').on('click',function(){		
		content_wrapper.empty();
		var item_id = $(this).data('id');
		$('#preview_dialog').dialog({
			height:500,
			width:700,
			modal:true,
			overlay : {
		        background: '#fff',
		        opacity: '0.7'
      		},
			open:function(){
				$.getJSON('/admin/video_scripts/' + item_id + '/body.json',function(response){					
					content_wrapper.html(response.body)					
				})
			}
		});		
	})	
})
