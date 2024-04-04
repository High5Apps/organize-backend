require "test_helper"

class PermissionTest < ActiveSupport::TestCase
  setup do
    @permission = permissions(:one_edit_permissions)
  end

  test 'should be valid' do
    assert @permission.valid?
  end

  test 'data should be present' do
    @permission.data = nil
    assert @permission.invalid?
  end

  test 'org should be present' do
    @permission.org = nil
    assert @permission.invalid?
  end

  test 'scope should be present' do
    @permission.scope = nil
    assert @permission.invalid?
  end

  test 'scope should be included in scopes' do
    @permission.scope = :bad_scope
    assert @permission.invalid?
  end

  test 'should not allow multiple with the same scope in an Org' do
    assert_no_difference 'Permission.count' do
      assert_raises do
        @permission.dup.save
      end
    end
  end
end
