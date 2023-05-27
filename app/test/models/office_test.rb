require "test_helper"

class OfficeTest < ActiveSupport::TestCase
  setup do
    @office = offices(:founder)
  end

  test 'should be valid' do
    assert @office.valid?
  end

  test 'name should be present' do
    @office.name = nil
    assert_not @office.valid?
  end
end
