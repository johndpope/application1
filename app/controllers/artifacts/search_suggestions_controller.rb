module Artifacts
  class SearchSuggestionsController < BaseController
    def index
      phrases = SearchSuggestion.order('phrase').matching_to(params[:phrase]).pluck('phrase')
      unique_words = -> (phrase) { phrase.split(/\s+/).uniq.join(' ') }
      respond_to do |format|
        format.json { render json: phrases.map(&unique_words) }
      end
    end
  end
end
