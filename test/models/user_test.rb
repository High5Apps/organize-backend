require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user_without_org = users(:two)
  end

  test 'should be valid' do
    assert @user.valid?
  end

  test 'org should be optional' do
    assert_nil @user_without_org.org
    assert @user_without_org.valid?
  end

  test 'public_key_bytes should be present' do
    @user.public_key_bytes = nil
    assert_not @user.valid?
  end

  test 'public_key_bytes should have the correct length' do
    @user.public_key_bytes = Base64.decode64('deadbeef')
    assert_not @user.valid?
  end
end
