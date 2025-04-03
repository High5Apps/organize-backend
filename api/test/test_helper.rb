ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/autorun"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def setup_test_key(user)
    key_pair = OpenSSL::PKey::EC.generate("prime256v1")
    user.private_key = key_pair
    user.update(public_key_bytes: key_pair.public_to_der)
  end

  def authorized_headers(requester, scope, expiration: nil,
    header: Authenticatable::HEADER_AUTHORIZATION
  )
    expiration ||= 1.minute.from_now
    token = requester.create_auth_token(expiration, scope)
    { header => bearer(token) }
  end

  def bearer(token)
    "Bearer #{token}"
  end

  def assert_contains_pagination_data
    assert_pattern do
      response.parsed_body => {
        meta: {
          current_page: Integer,
          next_page: Integer | nil,
        },
      }
    end

    response.parsed_body[:meta]
  end

  def unblock_all
    moderatables = ModerationEvent.group(:moderatable_type)
      .pluck(:moderatable_type)
      .map(&:constantize)
    moderatables.each do |moderatable|
      moderatable.update_all blocked_at: nil
    end

    ModerationEvent.destroy_all
  end

  def random_email
    "#{SecureRandom.uuid}@example.com"
  end

  def with_rails_credentials(temporary_credentials)
    original_credentials = Rails.application.credentials
    Rails.application.credentials = temporary_credentials
    yield
  ensure
    Rails.application.credentials = original_credentials
  end
end
