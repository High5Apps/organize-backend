class AppleMaps
  include HTTParty

  ALGORITHM = 'ES256'.freeze
  BASE_URI = 'https://maps-api.apple.com/v1'.freeze
  CACHE_KEY = 'apple_maps_access_token'.freeze
  LIMIT_TO_COUNTRIES = 'US'.freeze
  MAX_RETRIES = 1.freeze
  RACE_CONDITION_TTL = 1.minute.freeze
  REFRESH_TOKEN_TTL = 1.minute.freeze
  RESULT_TYPE_FILTER = 'Address'.freeze
  SEARCH_AUTOCOMPLETE_PATH = '/searchAutocomplete'.freeze
  TOKEN_PATH = '/token'.freeze
  TYPE = 'JWT'.freeze

  base_uri BASE_URI
  format :json

  class UnauthorizedError < StandardError; end

  def initialize(cache: nil, credentials: nil, sleep_method: nil)
    @cache = cache || Rails.cache
    @credentials = credentials || Rails.application.credentials
    @sleep_method = sleep_method || method(:sleep)
  end

  def search_autocomplete(query, latitude, longitude)
    retries = 0

    begin
      response = self.class.get SEARCH_AUTOCOMPLETE_PATH,
        headers: { Authorization: "Bearer #{access_token}" },
        query: {
          q: query,
          resultTypeFilter: RESULT_TYPE_FILTER,
          limitToCountries: LIMIT_TO_COUNTRIES,
          searchLocation: "#{latitude},#{longitude}",
        }
      case response.code
        when 200
          response.parsed_response
        when 401
          raise UnauthorizedError
        else
          raise HTTParty::Error.new response
      end
    rescue UnauthorizedError
      if retries < MAX_RETRIES
        @sleep_method.call 2**retries # Exponential backoff
        retries += 1
        retry
      end
    end
  end

  private

  def access_token
    @cache.fetch CACHE_KEY,
        race_condition_ttl: RACE_CONDITION_TTL, skip_nil: true do |key, options|
      request_start = Time.now
      response = self.class.get TOKEN_PATH,
        headers: { Authorization: "Bearer #{auth_token}" }
      if response.code == 200
        options.expires_at = request_start +
          response['expiresInSeconds'].to_i - RACE_CONDITION_TTL
        response['accessToken']
      end
    end
  end

  def auth_token
    apple_maps_credentials = @credentials.apple_maps!

    headers = {
      alg: ALGORITHM,
      kid: apple_maps_credentials.key_id!,
      typ: TYPE,
    }

    now = Time.now.to_i
    payload = {
      iss: apple_maps_credentials.team_id!,
      iat: now,
      exp: now + REFRESH_TOKEN_TTL.to_i,
    }

    private_key = OpenSSL::PKey::EC.new apple_maps_credentials.private_key!

    JWT.encode payload, private_key, ALGORITHM, headers
  end
end
