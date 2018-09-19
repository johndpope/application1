//= require aLTE/owl.carousel.js
//= require dashboard/video_workflow

var ready = function () {
  var owl = $('#owl-demo');

  owl.owlCarousel({
    items: 3, // 3 items above 1000px browser width
    itemsDesktop: [1000, 2],
    itemsDesktopSmall: [900, 1],
    itemsTablet: [600, 1],
    itemsMobile : false
  });

  // Custom Navigation Events
  $('.next').click(function () {
    owl.trigger('owl.next');
  });

  $('.prev').click(function () {
    owl.trigger('owl.prev');
  });

  var bot_server = $('#bot_server_id').select2();
  var youtube_channels_bot_server = $('#youtube_channels_bot_server_id').select2({allowClear: true});
  var youtube_videos_bot_server = $('#youtube_videos_bot_server_id').select2({allowClear: true});
  var phone_usages_period = $('#phone_usages_period').select2();
  var system_load_period = $('#system_load_period').select2();
  var video_workflow_period = $('#video_workflow_period').select2();
  var youtube_channels_period = $('#youtube_channels_period').select2();
  var youtube_videos_period = $('#youtube_videos_period').select2();
  var crawler_statuses_period = $('#crawler_statuses_period').select2();
  var email_accounts_period = $('#email_accounts_period').select2();
  var recovery_inbox_emails_period = $('#recovery_inbox_emails_period').select2();
  var recovery_attempt_answers_period = $('#recovery_attempt_answers_period').select2();
  var youtube_channels_client_id = $('#youtube_channels_client_id').select2({allowClear: true});
  var youtube_videos_client_id = $('#youtube_videos_client_id').select2({allowClear: true});

  bot_server.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });
  youtube_channels_bot_server.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });
  youtube_videos_bot_server.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });
  phone_usages_period.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });
  system_load_period.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });
  video_workflow_period.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });
  youtube_videos_period.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });
  youtube_channels_period.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });
  youtube_channels_client_id.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });
  youtube_videos_client_id.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });
  crawler_statuses_period.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });
  email_accounts_period.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });
  recovery_attempt_answers_period.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });
  recovery_inbox_emails_period.on('change', function (){
    document.body.style.cursor='wait';
    updateStatistics({
      'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
      'dashboard': '/dashboard.json?bot_server_id=',
      'hardware': '/server_hardware_json?bot_server_id='
    }, false);
  });


  function updateStatistics (object, loop) {
    for (i in object) sendAjaxRequest(object[i], i, loop);
  }

  function piwikStatistics() {
    $.ajax({
      type: 'GET',
      url: '/client_landing_pages/tools/visitors_statistics',
      dataType: 'html',
      error: function () {
        console.log('Error getting piwik statistics');
      },
      success: function (data) {
        $('#piwik_statistics').html(data);
      }
    });
  }

  var system_load_options = {
    title: {
      text: 'Server load',
      align: 'center'
    },
    xAxis: {
      visible: false,
      reversed: true
    },
    yAxis: {
      title: {
        text: null
      },
      plotLines: [{
        value: 0,
        width: 1,
        color: '#808080'
      }],
      min: 0,
      max: 100
    },
    tooltip: {
      formatter: function () {
        system_load_period_value = $('#system_load_period').val();
        if (system_load_period_value == '1') {
          x_value = Highcharts.numberFormat(this.x, 0);
          minute_str = "minutes";
          if (x_value == 1) {
            minute_str = "minute";
          }
          return '<b>'+ x_value + '</b> ' + minute_str + ' ago <br/>' + this.series.name + ': <b>' + Highcharts.numberFormat(this.y, 0) + '%</b>';
        } else if (system_load_period_value == '24' || system_load_period_value == '48'){
          x_value = Highcharts.numberFormat(this.x, 0);
          hour_str = "hours";
          if (x_value == 1) {
            hour_str = "hour";
          }
          return '<b>'+ x_value + '</b> ' + hour_str + ' ago <br/>' + this.series.name + ': <b>' + Highcharts.numberFormat(this.y, 0) + '%</b>';
        } else {
          days_value = Math.floor(Highcharts.numberFormat(this.x, 0) / 24);
          hours_value = Highcharts.numberFormat(this.x, 0) % 24;
          days_str = "days";
          hours_str = "hours"
          if (days_value == 1) {
            days_str = "day";
          }
          if (hours_value == 1){
            hours_str = "hour";
          }
          return '<b>'+ days_value + '</b> ' + days_str +' <b>' + hours_value + '</b> ' + hours_str + ' ago<br/>' + this.series.name + ': <b>' + Highcharts.numberFormat(this.y, 0) + '%</b>';
        }
      }
    },
    legend: {
      layout: 'horizontal',
      itemDistance: 50
    },
    series: [
      {
        name: 'CPU',
        data: []
      },
      {
        name: 'RAM',
        data: []
      },
      {
        name: 'Active threads',
        data: []
      }
    ],
    credits: {
      enabled: false
    }
  }

  $('#cpu_ram_last_hour_0').highcharts(system_load_options);

  function sendAjaxRequest (url, name, loop) {
    $.ajax({
      type: 'GET',
      url: url + $('#bot_server_id').val() + '&phone_usages_period=' + $('#phone_usages_period').val() + '&system_load_period=' + $('#system_load_period').val() + '&video_workflow_period=' + $('#video_workflow_period').val() + '&youtube_channels_period=' + $('#youtube_channels_period').val() + '&youtube_videos_period=' + $('#youtube_videos_period').val() + '&youtube_channels_bot_server_id=' + $('#youtube_channels_bot_server_id').val() + '&youtube_videos_bot_server_id=' + $('#youtube_videos_bot_server_id').val() + '&youtube_channels_client_id=' + $('#youtube_channels_client_id').val() + '&youtube_videos_client_id=' + $('#youtube_videos_client_id').val() + '&crawler_statuses_period=' + $('#crawler_statuses_period').val() + '&email_accounts_period=' + $('#email_accounts_period').val() + '&recovery_inbox_emails_period=' + $('#recovery_inbox_emails_period').val() + '&recovery_attempt_answers_period=' + $('#recovery_attempt_answers_period').val(),
      dataType: 'json',
      error: function () { console.log('Runtime error'); document.body.style.cursor='default';},
      success: function (data) {
        if (data['alert_system'] != undefined) {
          if (data['alert_system'] == true) {
            $(".logo").addClass("bg-red").addClass("blink");
            $(".navbar-static-top").addClass("bg-red").addClass("blink");
          } else {
            $(".logo").removeClass("bg-red").removeClass("blink");
            $(".navbar-static-top").removeClass("bg-red").removeClass("blink");
          }
        }
        if (url.indexOf('/server_hardware_json?bot_server_id=') !== -1) {
          var cpu_ram_load_chart = $('#cpu_ram_last_hour_0').highcharts();
          if (data['cpu_name_0'] != '') {
            cpu_ram_load_chart.series[0].setData(data['cpu_last_hour_0']);
            cpu_ram_load_chart.series[1].setData(data['ram_last_hour']);
            cpu_ram_load_chart.series[2].setData(data['active_threads_last_hour']);
          } else{
            cpu_ram_load_chart.series[0].setData([]);
            cpu_ram_load_chart.series[1].setData([]);
            cpu_ram_load_chart.series[2].setData([]);
          }
        }
        // if (data['not_published_videos_size'] != undefined) {
        //   published_videos_size = parseInt(data['published_videos_size'].replace(',', ''));
        //   not_published_videos_size = parseInt(data['not_published_videos_size'].replace(',', ''));
        //   pending_approval_videos_size = parseInt(data['pending_approval_videos_size'].replace(',', ''));
        //   total = published_videos_size + not_published_videos_size + pending_approval_videos_size;
        //   $('#youtube_videos_progress .published').css('width', published_videos_size * 100 / total + '%');
        //   $('#youtube_videos_progress .published span').text((published_videos_size * 100 / total).toFixed(0) + '%');
        //   $('#youtube_videos_progress .not-published').css('width', not_published_videos_size * 100 / total + '%');
        //   $('#youtube_videos_progress .not-published span').text((not_published_videos_size * 100 / total).toFixed(0) + '%');
        //   $('#youtube_videos_progress .pending').css('width', pending_approval_videos_size * 100 / total + '%');
        //   $('#youtube_videos_progress .pending span').text((pending_approval_videos_size * 100 / total).toFixed(0) + '%');
        // }
        add_urls_array = ['channels', 'total_pending_approval_business_channels', 'total_pending_approval_videos', 'total_published_business_channels', 'total_blocked_business_channels', 'total_not_published_business_channels', 'blocked_business_channels', 'not_blocked_business_channels', 'published_business_channels', 'not_published_business_channels', 'created_by_phone_business_channels', 'phone_verified_business_channels', 'phone_unverified_business_channels', 'filled_business_channels', 'unfilled_business_channels', 'pending_approval_business_channels', 'not_associated_websites',
        'total_published_videos', 'total_not_published_videos', 'total_deleted_videos', 'published_videos', 'not_published_videos', 'deleted_videos', 'not_deleted_videos', 'pending_approval_videos', 'videos', 'posted_on_google_plus_videos', 'not_posted_on_google_plus_videos', 'cards_posted', 'cards_not_posted', 'annotations_posted', 'annotations_not_posted', 'call_to_action_overlays_posted', 'call_to_action_overlays_not_posted', 'active_accounts_recovery_inbox_emails', 'inactive_accounts_recovery_inbox_emails', 'active_accounts_status_changed', 'inactive_accounts_status_changed', 'recovery_attempts_missing', 'active_accounts_pool']
        for (i in add_urls_array) {
          item = add_urls_array[i];
          if(data[item + '_size'] != undefined){
            $('#dashboard_' + item + '_size').attr('href', data[item + '_url']);
          }
        }
        if (data['inactive_accounts_status_changed_size'] != undefined) {
          if (parseInt(data['inactive_accounts_status_changed_size'].replace(/\D+/g, '')) >= 3) {
            $('#dashboard_inactive_accounts_status_changed_size').addClass("blink").addClass("warning-td");
          } else {
            $('#dashboard_inactive_accounts_status_changed_size').removeClass("blink").removeClass("warning-td");
          }
        }
        if (data['created_email_accounts_size'] != undefined) {
          created_email_accounts_size = parseInt(data['created_email_accounts_size']);
          ordered_email_accounts_size = parseInt(data['ordered_email_accounts_size']);
          if (ordered_email_accounts_size > 0) {
            if (data['show_account_creation_progress'] == true) {
              created_accounts_persantage = created_email_accounts_size * 100 / ordered_email_accounts_size;
              $('#account_creation_progress .created').css('width', created_accounts_persantage + '%');
              $('#account_creation_progress span').text(created_email_accounts_size + ' / ' + ordered_email_accounts_size + ' (' +(created_accounts_persantage ).toFixed(0) + '% Done)');
            } else {
              $('#account_creation_progress span').text(ordered_email_accounts_size + ' / ' + ordered_email_accounts_size + ' (100% Done)');
              $('#account_creation_progress .created').css('width', '100%');
              $('#account_creation_progress .created').removeClass('progress-bar-primary active').addClass('progress-bar-success');
            }
            $('#account_creation_progress').show();
          } else {
            $('#account_creation_progress').hide();
          }
        }
        for (i in data) {
          if ( (element = $('#' + name + '_' + i))[0] ) {
            if (i == 'ram_usage' || i == 'ram') data[i] = (data[i] / 1024).toFixed(2);
            element.text(data[i]);
          } else if (i == '') {

          } else if (i == 'recovery_attempt_style') {
            //$('#prgs .progress-bar').removeClass().addClass(data[i]);
          } else if (i == 'recovery_attempts_percentage') {
            //$('#prgs .progress-bar').css('width', data[i] + '%');
          } else if (i == 'recovery_statistics') {
            var myTrs = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrs += '<tr><td class="text-center">' + el['answer'] + '</td><td>' + el['name'] + '</td><td class="text-center"><a href="' + el['url'] + '" target="_blank">' + el['count'] + '</a></td></tr>';
            }

            $('#recovery_statistics').html(myTrs);
          } else if (i == 'google_recovery_inbox_emails') {
            var myTgries = "";
            for (e in data[i]) {
              el = data[i][e];
              myTgries += '<tr><td class="text-center">' + el['code'] + '</td><td>' + el['name'] + '</td><td class="text-center"><a href="' + el['url'] + '" target="_blank">' + el['count'] + '</a></td></tr>';
            }

            $('#google_recovery_inbox_emails').html(myTgries);
          } else if (i == 'youtube_recovery_inbox_emails') {
            var myTyries = "";
            for (e in data[i]) {
              el = data[i][e];
              myTyries += '<tr><td class="text-center">' + el['code'] + '</td><td>' + el['name'] + '</td><td class="text-center"><a href="' + el['url'] + '" target="_blank">' + el['count'] + '</a></td></tr>';
            }

            $('#youtube_recovery_inbox_emails').html(myTyries);
          } else if (i == 'phone_usages_statistics') {
            var myTrsPus = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrsPus += '<tr><td class="overflow">' + el['action_type'] + '</td><td class="overflow">' + el['error_type'] + '</td><td class="text-center"><a href="' + el['url'] + '" target="_blank">' + el['count'] + '</a></td></tr>';
            }

            $('#phone_usages_statistics').html(myTrsPus);
          } else if (i == 'crawler_statuses_style') {
            $('#crawler_prgs .progress-bar').removeClass().addClass(data[i]);
          } else if (i == 'crawler_statuses_percentage') {
            $('#crawler_prgs .progress-bar').css('width', data[i] + '%');
          } else if (i == 'crawler_statuses_statistics') {
            var myTrsCrSs = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrsCrSs += '<tr><td class="overflow">' + el['status'] + '</td><td class="overflow">' + el['count'] + '</td></tr>';
            }

            $('#crawler_statuses_statistics').html(myTrsCrSs);
          } else if (i == 'api_accounts_statistics') {
            var myTpsas = "";
            for (e in data[i]) {
              el = data[i][e];
              myTpsas += '<tr><td class="text-center"><a href="' + el['url'] + '" target="_blank">' + el['id'] + '</a></td><td>' + el['name'] + '</td><td class="text-center">' + el['success_attempts_size'] + '</td><td class="text-center">' + el['unsuccess_attempts_size'] + '</td><td class="text-center">' + el['current_bid'] + '</td><td><i class="fa fa-' + el['currency'] + '"></i> ' + el['balance'] + '</td></tr>';
            }
            $('#api_accounts_statistics').html(myTpsas);
          } else if (i == 'broadcaster_hdds') {
            var myTrBrHdds = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrBrHdds += '<tr><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] + '</td><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[4] + '</td><td>' + el[5] + '</td></tr>';
            }
            $('#broadcaster_hdds').html(myTrBrHdds);
          } else if (i == 'delayed_jobs_0_hdds') {
            var myTrDjHdds0 = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrDjHdds0 += '<tr><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] + '</td><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[4] + '</td><td>' + el[5] + '</td></tr>';
            }
            $('#delayed_jobs_0_hdds').html(myTrDjHdds0);
          } else if (i == 'delayed_jobs_1_hdds') {
            var myTrDjHdds1 = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrDjHdds1 += '<tr><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] + '</td><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[4] + '</td><td>' + el[5] + '</td></tr>';
            }
            $('#delayed_jobs_1_hdds').html(myTrDjHdds1);
          } else if (i == 'delayed_jobs_2_hdds') {
            var myTrDjHdds2 = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrDjHdds2 += '<tr><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] + '</td><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[4] + '</td><td>' + el[5] + '</td></tr>';
            }
            $('#delayed_jobs_2_hdds').html(myTrDjHdds2);
          } else if (i == 'database_hdds') {
            var myTrDbHdds = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrDbHdds += '<tr><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] + '</td><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[4] + '</td><td>' + el[5] + '</td></tr>';
            }
            $('#database_hdds').html(myTrDbHdds);
          } else if (i == 'nas_hdds') {
            var myTrNasHdds = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrNasHdds += '<tr><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] + '</td><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[4] + '</td><td>' + el[5] + '</td></tr>';
            }
            $('#nas_hdds').html(myTrNasHdds);
          } else if (i == 'broadcaster_cpu_load_average') {
            var myTrBrCpuAvg = "";
            el = data[i];
            if (el.length > 0) {
              myTrBrCpuAvg += '<tr><td class="text-center">' + el[0] + '</td><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] / 2 + '</td><td class="text-center">' + el[3] + '</td></tr>';
            }
            $('#broadcaster_cpu_load_average').html(myTrBrCpuAvg);
          } else if (i == 'delayed_jobs_0_cpu_load_average') {
            var myTrDjCpuAvg0 = "";
            el = data[i];
            if (el.length > 0) {
              myTrDjCpuAvg0 += '<tr><td class="text-center">' + el[0] + '</td><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] / 2 + '</td><td class="text-center">' + el[3] + '</td></tr>';
            }
            $('#delayed_jobs_0_cpu_load_average').html(myTrDjCpuAvg0);
          } else if (i == 'delayed_jobs_1_cpu_load_average') {
            var myTrDjCpuAvg1 = "";
            el = data[i];
            if (el.length > 0) {
              myTrDjCpuAvg1 += '<tr><td class="text-center">' + el[0] + '</td><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] / 2 + '</td><td class="text-center">' + el[3] + '</td></tr>';
            }
            $('#delayed_jobs_1_cpu_load_average').html(myTrDjCpuAvg1);
          } else if (i == 'delayed_jobs_2_cpu_load_average') {
            var myTrDjCpuAvg2 = "";
            el = data[i];
            if (el.length > 0) {
              myTrDjCpuAvg2 += '<tr><td class="text-center">' + el[0] + '</td><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] / 2 + '</td><td class="text-center">' + el[3] + '</td></tr>';
            }
            $('#delayed_jobs_2_cpu_load_average').html(myTrDjCpuAvg2);
          } else if (i == 'database_cpu_load_average') {
            var myTrDbCpuAvg = "";
            el = data[i];
            if (el.length > 0) {
              myTrDbCpuAvg += '<tr><td class="text-center">' + el[0] + '</td><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] / 2 + '</td><td class="text-center">' + el[3] + '</td></tr>';
            }
            $('#database_cpu_load_average').html(myTrDbCpuAvg);
          } else if (i == 'nas_cpu_load_average') {
            var myTrNasCpuAvg = "";
            el = data[i];
            if (el.length > 0) {
              myTrNasCpuAvg += '<tr><td class="text-center">' + el[0] + '</td><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] / 2 + '</td><td class="text-center">' + el[3] + '</td></tr>';
            }
            $('#nas_cpu_load_average').html(myTrNasCpuAvg);
          } else if (i == 'broadcaster_memory') {
            var myTrBrMem = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrBrMem += '<tr><th class="text-center">' + el[0] + '</th><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] + '</td><td class="text-center">' + el[4] + '</td><td class="text-center">' + el[5] + '</td><td class="text-center">' + el[6] + '</td></tr>';
            }
            $('#broadcaster_memory').html(myTrBrMem);
          } else if (i == 'delayed_jobs_0_memory') {
            var myTrDjMem0 = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrDjMem0 += '<tr><th class="text-center">' + el[0] + '</th><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] + '</td><td class="text-center">' + el[4] + '</td><td class="text-center">' + el[5] + '</td><td class="text-center">' + el[6] + '</td></tr>';
            }
            $('#delayed_jobs_0_memory').html(myTrDjMem0);
          } else if (i == 'delayed_jobs_1_memory') {
            var myTrDjMem1 = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrDjMem1 += '<tr><th class="text-center">' + el[0] + '</th><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] + '</td><td class="text-center">' + el[4] + '</td><td class="text-center">' + el[5] + '</td><td class="text-center">' + el[6] + '</td></tr>';
            }
            $('#delayed_jobs_1_memory').html(myTrDjMem1);
          } else if (i == 'delayed_jobs_2_memory') {
            var myTrDjMem2 = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrDjMem2 += '<tr><th class="text-center">' + el[0] + '</th><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] + '</td><td class="text-center">' + el[4] + '</td><td class="text-center">' + el[5] + '</td><td class="text-center">' + el[6] + '</td></tr>';
            }
            $('#delayed_jobs_2_memory').html(myTrDjMem2);
          } else if (i == 'database_memory') {
            var myTrDbMem = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrDbMem += '<tr><th class="text-center">' + el[0] + '</th><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] + '</td><td class="text-center">' + el[4] + '</td><td class="text-center">' + el[5] + '</td><td class="text-center">' + el[6] + '</td></tr>';
            }
            $('#database_memory').html(myTrDbMem);
          } else if (i == 'nas_memory') {
            var myTrNasMem = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrNasMem += '<tr><th class="text-center">' + el[0] + '</th><td class="text-center">' + el[1] + '</td><td class="text-center">' + el[2] + '</td><td class="text-center">' + el[3] + '</td><td class="text-center">' + el[4] + '</td><td class="text-center">' + el[5] + '</td><td class="text-center">' + el[6] + '</td></tr>';
            }
            $('#nas_memory').html(myTrNasMem);
          } else if (i == 'dids_statistics') {
            var myTdids = "";
            for (e in data[i]) {
              el = data[i][e];

              myTdids += '<tr><td class="text-center"><a href="' + el['by_country_url'] + '" target="_blank">' + el['country_code'] + '</a></td><td>' + el['region_name'] + '</td><td class="text-center"><a href="' + el['url'] + '" target="_blank">' + el['count'] + '</a></td></tr>';
            }
            $('#dids_statistics').html(myTdids);
          } else if (i == 'templates_aae_projects') {
            var myTrsAaeProjects = "";
            $.each(data[i], function (key, d) {
              if (key != 'Total') {
                myTrsAaeProjects += '<tr><td class="overflow">' + key + '</td><td class="text-center"><a href="' + d['url'] + 'true" target="_blank" title="Approved">' + d['true'] + '</a></td><td class="text-center"><a href="' + d['url'] + 'false" target="_blank" title="Not Approved">' + d['false'] + '</a></td></tr>';
              } else {
                myTrsAaeProjects += '<tr><td class="overflow" style="font-weight: bold;">' + key + '</td><td class="text-center" style="font-weight: bold;"><a href="' + d['url'] + 'true" target="_blank" title="Approved">' + d['true'] + '</a></td><td class="text-center" style="font-weight: bold;"><a href="' + d['url'] + 'false" target="_blank" title="Not Approved">' + d['false'] + '</a></td></tr>';
              }
            });
            $('#templates_aae_projects').html(myTrsAaeProjects);
          } else if (i == 'problems') {
            var myTdproblems = "";
            for (e in data[i]) {
              el = data[i][e];
              myTdproblems += '<tr><td>' + el + '</td></tr>';
            }
            $('#problems').html(myTdproblems);
            if (myTdproblems == '') {
              $('#problems_box').hide();
            } else {
              $('#problems_box').show();
            }
          } else if (i = 'clients_statistics') {
            var myTrsCls = "";
            for (e in data[i]) {
              el = data[i][e];
              myTrsCls += '<a href="javascript://" data-legend-url="' + el['legend_url'] + '">' + el['name'] + '</a>&nbsp;&nbsp; · &nbsp;&nbsp;';
            }
            var lastIndex = myTrsCls.lastIndexOf("&nbsp;&nbsp; · &nbsp;&nbsp;");
            myTrsCls = myTrsCls.substring(0, lastIndex);
            if (myTrsCls != "") {
              $('#clients_statistics').html(myTrsCls);
            }
          }
        }
        if (data['active_accounts_recovery_inbox_email_action_required'] != undefined) {
          if (data['active_accounts_recovery_inbox_email_action_required'] == true) {
            $('#dashboard_active_accounts_recovery_inbox_emails_size').addClass("warning-td").addClass('blink');
          } else {
            $('#dashboard_active_accounts_recovery_inbox_emails_size').removeClass("warning-td").removeClass('blink');
          }
        }
        if (data['inactive_accounts_recovery_inbox_email_action_required'] != undefined) {
          if (data['inactive_accounts_recovery_inbox_email_action_required'] == true) {
            $('#dashboard_inactive_accounts_recovery_inbox_emails_size').addClass("warning-td").addClass('blink');
          } else {
            $('#dashboard_inactive_accounts_recovery_inbox_emails_size').removeClass("warning-td").removeClass('blink');
          }
        }
        document.body.style.cursor='default';
      }
    }).done(setTimeout(function (data) {
      if(loop){
        sendAjaxRequest (url, name, true);
      }
    }, 60000));
  }

  updateStatistics({
    'active_threads': '/bot_statistics_json?thread=active&bot_server_id=',
    'dashboard': '/dashboard.json?bot_server_id=',
    'hardware': '/server_hardware_json?bot_server_id='
  }, true);
  piwikStatistics();

  $('body').on('click', '*[data-legend-url]', function (event) {
		element = $(this);
		$('#client_legend').empty();
		$.ajax({ url: element.data('legend-url') }).done(function (response) {
			$('#client_legend').append(response).modal();
		});
	});
}

$(document).ready(ready);
$(document).on('page:load', ready);
