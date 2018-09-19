module PiwikService
  PIWIK_SERVER_URL = "http://192.99.120.165"
  START_DATE = "2016-03-08"
  class << self
    def visitors_statistics_json
      response = get_piwik_response("API", "MultiSites.getAll", {"period" => "range", "date" => "#{Setting.get_value_by_name('PiwikService::START_DATE')},#{Time.now.strftime('%Y-%m-%d')}", "filter_limit" => "-1"})
      json = if response.present? && response.is_a?(Net::HTTPSuccess)
        begin
          JSON.parse(response.body)
        rescue JSON::ParserError => e
          []
        end
      else
        []
      end
    end

    def get_detailed_statistics(piwik_id=nil, date_to = Time.now)
      response = get_piwik_response("API", "API.get", {"idSite" => piwik_id, "period" => "range", "date" => "#{Setting.get_value_by_name('PiwikService::START_DATE')},#{date_to.strftime('%Y-%m-%d')}", "columns"=>"nb_visits,nb_actions,nb_pageviews"})
      json = if response.present? && response.is_a?(Net::HTTPSuccess)
        begin
          JSON.parse(response.body)
        rescue JSON::ParserError => e
          []
        end
      else
        []
      end
    end

    def get_piwik_response(piwik_module, method, options={})
      params = {
        "module" => piwik_module,
        "method" => method,
        "format" => "JSON",
        "token_auth" => CONFIG['piwik']['token_auth']
      }

      uri = URI.parse("#{Setting.get_value_by_name('PiwikService::PIWIK_SERVER_URL')}/piwik/index.php")
      uri.query = URI.encode_www_form(params.merge(options))
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 300
      http.open_timeout = 300
      response = http.start() {|http|
        http.get(uri.request_uri)
      }
    end

    def get_all_statistics
      now = Time.now
      PiwikStatistic.where("created_at < ?", now - 30.days).destroy_all
      clps = ClientLandingPage.where("piwik_id IS NOT NULL")
      clps.each do |clp|
        r = get_detailed_statistics(clp.piwik_id, now)
        if r.present?
          r["client_landing_page_id"] = clp.id
          ps = PiwikStatistic.create(r)
          ps.update_attributes(updated_at: now, created_at: now) if ps
        end
      end
    end
  end
end
