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
  AUTHORIZATION = Authenticatable::HEADER_AUTHORIZATION
  SCOPE_ALL = Authenticatable::SCOPE_ALL

  setup do
    @user = users(:one)
    setup_test_key(@user)

    @authentication = MockController.new
  end

  test 'should not get user from empty token' do
    @authentication.request.headers[AUTHORIZATION] = nil
    assert_nil @authentication.authenticated_user
  end

  test 'should not get user from expired token' do
    freeze_time do
      expired_token = @user.create_auth_token FAKE_AUTH_TIMEOUT.from_now,
        SCOPE_ALL
      @authentication.request.headers[AUTHORIZATION] = bearer(expired_token)

      travel FAKE_AUTH_TIMEOUT
      assert_nil @authentication.authenticated_user
    end
  end

  test 'should not get user from bad token' do
    bad_token = @user.create_auth_token(
      FAKE_AUTH_TIMEOUT.from_now, SCOPE_ALL
    ) + 'bad'
    @authentication.request.headers[AUTHORIZATION] = bearer(bad_token)
    assert_nil @authentication.authenticated_user
  end

  test 'should get user from correct, non-expired token' do
    freeze_time do
      auth_token = @user.create_auth_token(FAKE_AUTH_TIMEOUT.from_now, SCOPE_ALL)
      @authentication.request.headers[AUTHORIZATION] = bearer(auth_token)

      travel FAKE_AUTH_TIMEOUT - 1.second
      assert_equal @user, @authentication.authenticated_user
    end
  end

  test 'should not get user from correct token without expiration' do
    freeze_time do
      auth_token = @user.create_auth_token(nil, SCOPE_ALL)
      @authentication.request.headers[AUTHORIZATION] = bearer(auth_token)

      travel -10.seconds
      assert_nil @authentication.authenticated_user
    end
  end

  test 'should not get user from correct token without Bearer prefix' do
    freeze_time do
      auth_token = @user.create_auth_token(FAKE_AUTH_TIMEOUT.from_now, SCOPE_ALL)
      @authentication.request.headers[AUTHORIZATION] = auth_token

      travel FAKE_AUTH_TIMEOUT - 1.second
      assert_nil @authentication.authenticated_user
    end
  end

  test 'should not get user from correct token without scope' do
    freeze_time do
      auth_token = @user.create_auth_token(FAKE_AUTH_TIMEOUT.from_now, nil)
      @authentication.request.headers[AUTHORIZATION] = bearer(auth_token)

      travel FAKE_AUTH_TIMEOUT - 1.second
      assert_nil @authentication.authenticated_user
    end
  end

  test 'should not get user from correct token with incorrect scope' do
    freeze_time do
      auth_token = @user.create_auth_token(
        FAKE_AUTH_TIMEOUT.from_now,
        Authenticatable::SCOPE_CREATE_CONNECTIONS)
      @authentication.request.headers[AUTHORIZATION] = bearer(auth_token)

      travel FAKE_AUTH_TIMEOUT - 1.second
      assert_nil  @authentication.authenticated_user
    end
  end

  test 'should authorize any scope with * scope' do
    auth_token = @user.create_auth_token(FAKE_AUTH_TIMEOUT.from_now, SCOPE_ALL)
    @authentication.request.headers[AUTHORIZATION] = bearer(auth_token)
    assert @authentication.authenticate(scope: 'read:foos')
  end
end
