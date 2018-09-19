window.artifacts_common_home = ->
  $.get '/artifacts/images/region1_coverage.json', (data) ->
    country = new jvm.Map
      container: $('#country'),
      map: 'us_lcc_en',
      series:
        regions: [{
          values: data,
          scale: ['#C8EEFF', '#0071A4'],
          normalizeFunction: 'polynomial'
        }]
      regionsSelectable: true,
      regionsSelectableOne: true,
      regionLabelStyle:
        initial:
          fill: '#B90E32'
        hover:
          fill: 'black'
      labels:
        regions:
          render: (code) -> code.split('-')[1]
      onRegionTipShow: (e, el, code) ->
        el.html("#{el.html()}<br>(Images: #{data[code]})")
      onRegionClick: (event, code) ->
        $('#region').empty()
        $.get "/artifacts/images/region2_coverage.json?region1=#{code}", (data) ->
          new jvm.Map
            container: $('#region')
            map: "#{code.toLowerCase()}_lcc_en",
            series:
              regions: [{
                values: data,
                scale: ['#C8EEFF', '#0071A4'],
                normalizeFunction: 'polynomial'
              }]
            labels:
              regions:
                render: (code) ->
                  parts = code.split(' ')
                  parts.slice(1, parts.length - 1).join(' ')
            onRegionTipShow: (e, el, code) ->
              el.html("#{el.html()}<br>(Images #{data[code]})")
            regionLabelStyle:
              initial:
                fill: '#B90E32'
              hover:
                fill: 'black'
