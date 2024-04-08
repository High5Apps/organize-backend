require "test_helper"

class PermissionDataTest < ActiveSupport::TestCase
  setup do
    @permission_data = permissions(:one_edit_permissions).data
  end

  test 'should be valid' do
    assert @permission_data.valid?
  end

  test 'should not include unexpected attributes' do
    assert_raises { Permission::Data.new bad_attribute: 'foo' }
  end

  test 'offices should be present' do
    @permission_data.offices = nil
    assert @permission_data.invalid?
  end

  test 'offices should not be empty' do
    @permission_data.offices = []
    assert @permission_data.invalid?
  end

  test 'offices should only include offices' do
    @permission_data.offices = ['bad_office']
    assert @permission_data.invalid?
  end

  test 'offices should not contain duplicates' do
    @permission_data.offices = ['founder', 'founder']
    assert @permission_data.invalid?
  end
end
