ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

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

  def authorized_headers(requester, scope, expiration=nil)
    expiration ||= 1.minute.from_now
    token = requester.create_auth_token(expiration, scope)
    { Authorization: bearer(token) }
  end

  def bearer(token)
    "Bearer #{token}"
  end
end
