require "test_helper"

class Api::V1::FlagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @flag = flags :one
    @flaggables = [ballots(:one), comments(:one), posts(:one)]

    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)
  end

  test 'should create with valid params' do
    @flaggables.each do |flaggable|
      assert_difference 'Flag.count', 1 do
        post api_v1_flags_url,
          headers: @authorized_headers,
          params: create_params(flaggable)
      end

      assert_response :created
      assert_empty response.body
    end
  end

  test 'should no-op when trying to double create' do
    [1, 0].each do |expected_difference|
      @flaggables.each do |flaggable|
        assert_difference 'Flag.count', expected_difference do
          post api_v1_flags_url,
            headers: @authorized_headers,
            params: create_params(flaggable)
          assert_response :created
        end
      end
    end
  end

  test 'should not create with invalid authorization' do
    @flaggables.each do |flaggable|
      assert_no_difference 'Flag.count' do
        post api_v1_flags_url,
          headers: authorized_headers(@user,
            Authenticatable::SCOPE_ALL,
            expiration: 1.second.ago),
          params: create_params(flaggable)
      end

      assert_response :unauthorized
    end
  end

  private

  def create_params(flaggable)
    @flag.flaggable = flaggable
    { flag: @flag.as_json }
  end
end
