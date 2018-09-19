window.admin_sandbox_video_campaign_video_stages_index = ->
	$('body').popover
		selector: 'a.tags-toggle',
		content: ->
			labels = $.map $(this).data('tags').toString().split(','), (e) ->
				"<span class='label label-info'>#{e}</span>"
			labels.join(' ')
		html: true,
		placement: 'top',
		trigger: 'hover'

	description_popover = (selector) ->
		$(selector).popover
			placement: 'top',
			trigger: 'hover'

	description_popover("[data-id=#{$(desc_item).data('id')}]") for desc_item in $('.description-toggle')

	$('#q_video_campaign_id_eq').select2
		placeholder: 'Choose',
		width: '100%',
		minimumInputLength: 0,
		allowClear: true,
		ajax:
			url: '/admin/sandbox/video_campaigns.json',
			quietMillis: 300,
			data: (term, page) ->
				{
					"q[client_id_eq]": $('#q_video_campaign_client_id_eq').val(),
					page: page,
					per_page: 10
				}
			results: (data, page) ->
				{
					results: $.map(data.items, (e) -> { id: e.id, text: e.title }),
					more: (page * 10) < data.total
				}
	current_video_campaign_json = JSON.parse($('#current_video_campaign_json').val())
	$('#q_video_campaign_id_eq').select2('data', {id: current_video_campaign_json.id, text: current_video_campaign_json.title}) if current_video_campaign_json? && current_video_campaign_json?.title
