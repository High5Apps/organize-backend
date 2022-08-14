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
    private_key = OpenSSL::PKey::RSA.generate 2048
    user.private_key = private_key
    user.update(public_key_bytes: private_key.public_key.to_der)
  end
end
