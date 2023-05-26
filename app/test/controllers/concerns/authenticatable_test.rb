require "test_helper"

class MockController
  include Authenticatable

  attr_accessor :request
  attr_accessor :logger

  def initialize
    mock_request = Struct.new(:headers)
    self.request = mock_request.new({})
    self.logger = Rails.logger
  end
end

class AuthenticatableTest < ActionDispatch::IntegrationTest
  FAKE_AUTH_TIMEOUT = 1.minute

  setup do
    @user = users(:one)
    setup_test_key(@user)

    @authentication = MockController.new
  end

  test 'should not get user from empty token' do
    @authentication.request.headers['Authorization'] = nil
    assert_nil @authentication.authenticated_user
  end

  test 'should not get user from expired token' do
    expired_token = @user.create_auth_token(FAKE_AUTH_TIMEOUT.from_now, '*')
    @authentication.request.headers['Authorization'] = bearer(expired_token)
    travel (FAKE_AUTH_TIMEOUT) do
      assert_nil @authentication.authenticated_user
    end
  end

  test 'should not get user from bad token' do
    bad_token = @user.create_auth_token(FAKE_AUTH_TIMEOUT.from_now, '*') + 'bad'
    @authentication.request.headers['Authorization'] = bearer(bad_token)
    assert_nil @authentication.authenticated_user
  end

  test 'should get user from correct, non-expired token' do
    auth_token = @user.create_auth_token(FAKE_AUTH_TIMEOUT.from_now, '*')
    @authentication.request.headers['Authorization'] = bearer(auth_token)
    travel (FAKE_AUTH_TIMEOUT - 1.second) do
      assert_equal @user, @authentication.authenticated_user
    end
  end

  test 'should not get user from correct token without expiration' do
    auth_token = @user.create_auth_token(nil, '*')
    @authentication.request.headers['Authorization'] = bearer(auth_token)
    travel -10.seconds do
      assert_nil @authentication.authenticated_user
    end
  end

  test 'should not get user from correct token without Bearer prefix' do
    auth_token = @user.create_auth_token(FAKE_AUTH_TIMEOUT.from_now, '*')
    @authentication.request.headers['Authorization'] = auth_token
    travel (FAKE_AUTH_TIMEOUT - 1.second) do
      assert_nil @authentication.authenticated_user
    end
  end

  test 'should not get user from correct token without scope' do
    auth_token = @user.create_auth_token(FAKE_AUTH_TIMEOUT.from_now, nil)
    @authentication.request.headers['Authorization'] = bearer(auth_token)
    travel (FAKE_AUTH_TIMEOUT - 1.second) do
      assert_nil @authentication.authenticated_user
    end
  end

  test 'should not get user from correct token with incorrect scope' do
    auth_token = @user.create_auth_token(
      FAKE_AUTH_TIMEOUT.from_now,
      'create:connections')
    @authentication.request.headers['Authorization'] = bearer(auth_token)
    travel (FAKE_AUTH_TIMEOUT - 1.second) do
      assert_nil  @authentication.authenticated_user
    end
  end

  test 'should authorize any scope with * scope' do
    auth_token = @user.create_auth_token(FAKE_AUTH_TIMEOUT.from_now, '*')
    assert @authentication.authenticate(auth_token, 'read:foos')
  end
end