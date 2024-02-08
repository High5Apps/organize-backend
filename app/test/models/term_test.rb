require "test_helper"

class TermTest < ActiveSupport::TestCase
  setup do
    @term = terms(:one)
  end

  test 'should be valid' do
    assert @term.valid?
  end

  test 'user should be present' do
    @term.user = nil
    assert_not @term.valid?
  end

  test 'office should be present' do
    @term.office = nil
    assert_not @term.valid?
  end

  test 'category should be present' do
    @term.category = nil
    assert @term.invalid?
  end
end
