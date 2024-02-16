require "test_helper"

class TermTest < ActiveSupport::TestCase
  setup do
    @term = terms(:one)
  end

  test 'should be valid' do
    assert @term.valid?
  end

  test 'ends_at should be present' do
    @term.ends_at = nil
    assert @term.invalid?
  end

  test 'ends_at should be after created_at' do
    @term.ends_at = @term.created_at
    assert @term.invalid?

    @term.ends_at = @term.created_at + 1.second
    assert @term.valid?
  end

  test 'office should be present' do
    @term.office = nil
    assert @term.invalid?
  end

  test 'user should be present' do
    @term.user = nil
    assert_not @term.valid?
  end
end
