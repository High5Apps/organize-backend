require "test_helper"

class OrgTest < ActiveSupport::TestCase
  setup do
    @org = orgs(:one)
  end

  test 'should be valid' do
    assert @org.valid?
  end

  test 'name should be present' do
    @org.name = ' '
    assert_not @org.valid?
  end

  test 'name should not be too long' do
    @org.name = 'a' * Org::MAX_NAME_LENGTH
    assert @org.valid?

    @org.name = 'a' * (1 + Org::MAX_NAME_LENGTH)
    assert_not @org.valid?
  end

  test 'potential_member_definition should be present' do
    @org.potential_member_definition = ' '
    assert_not @org.valid?
  end

  test 'potential_member_definition should not be too long' do
    @org.potential_member_definition =
      'a' * Org::MAX_POTENTIAL_MEMBER_DEFINITION_LENGTH
    assert @org.valid?

    @org.potential_member_definition =
      'a' * (1 + Org::MAX_POTENTIAL_MEMBER_DEFINITION_LENGTH)
    assert_not @org.valid?
  end

  test 'potential_member_estimate should be present' do
    @org.potential_member_estimate = nil
    assert_not @org.valid?
  end

  test 'potential_member_estimate should be an integer' do
    @org.potential_member_estimate = 200.5
    assert_not @org.valid?
  end

  test 'potential_member_estimate should not be too small' do
    @org.potential_member_estimate = Org::MIN_POTENTIAL_MEMBER_ESTIMATE
    assert @org.valid?

    @org.potential_member_estimate = Org::MIN_POTENTIAL_MEMBER_ESTIMATE - 1
    assert_not @org.valid?
  end

  test 'potential_member_estimate should not be too large' do
    @org.potential_member_estimate = Org::MAX_POTENTIAL_MEMBER_ESTIMATE
    assert @org.valid?

    @org.potential_member_estimate = Org::MAX_POTENTIAL_MEMBER_ESTIMATE + 1
    assert_not @org.valid?
  end
end
