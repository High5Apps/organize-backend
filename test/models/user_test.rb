require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test 'should be valid' do
    assert @user.valid?
  end

  test 'org should be present' do
    @user.org = nil
    assert_not @user.valid?
  end

  test 'public_key should be present' do
    @user.public_key = nil
    assert_not @user.valid?
  end

  test 'public_key should have the correct length' do
    @user.public_key = Base64.decode64('deadbeef')
    assert_not @user.valid?
  end
end
