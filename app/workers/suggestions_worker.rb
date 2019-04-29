class SuggestionsWorker
  include Sidekiq::Worker

  def perform
    Suggestions.refresh
  end
end
