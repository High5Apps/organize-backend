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

  test 'should set pseudonym when org_id is initially set' do
    assert_nil @user_without_org.pseudonym
    @user_without_org.update!(org: orgs(:one))
    assert_not_nil @user_without_org.reload.pseudonym
  end

  test 'should set joined_at when org_id is initially set' do
    assert_nil @user_without_org.joined_at
    @user_without_org.update!(org: orgs(:one))
    assert_not_nil @user_without_org.reload.joined_at
  end

  test 'should create a founder term when org is created and set on creator' do
    org = orgs :one
    @user_without_org.create_org org.attributes.except 'id'
    assert_difference 'Term.count', 1 do
      @user_without_org.save
    end
  end
end
