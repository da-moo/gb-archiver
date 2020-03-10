# frozen_string_literal: true

require 'faraday'
require 'json'

# Wrapper for consuming the Giant Bomb API
class GbApi
  CURRENT_LIVE_ENDPOINT = 'https://www.giantbomb.com/api/video/current-live/'
  attr_reader :api_key

  # Creates the object with an API key
  def initialize(api_key, logger)
    @api_key = api_key
    @log = logger
  end

  def current_live
    response = Faraday.get(CURRENT_LIVE_ENDPOINT,
                           { api_key: @api_key },
                           { 'Accept' => 'application/json' })
    response_hash = JSON.parse(response.body, symbolize_names: true)
    @log.info('GB API response: ' + response_hash.to_s)
    response_hash
  rescue StandardError => e
    @log.error('API failed: ' + e.full_message)
    { video: nil }
  end
end
