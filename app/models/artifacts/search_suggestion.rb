module Artifacts
  class SearchSuggestion < ActiveRecord::Base
    self.table_name = 'artifacts_search_suggestions_view'

    class << self
      def matching_to(text)
        tokens = sanitize(text).split(/\W/).map(&:downcase).uniq.select(&:present?)
        operand = '&'
        terms = -> { tokens.join(" #{operand} ") }
        filter = -> { "to_tsvector('english', phrase) @@ to_tsquery('#{terms.call}')" }
        rank = -> { "ts_rank(to_tsvector(phrase), to_tsquery('#{terms.call}'))" }
        search = -> { where(filter.call) }
        if (fetch = search.call).any?
          fetch
        else
          operand = '|'
          search.call
        end.order("#{rank.call} DESC")
      end
    end
  end
end
