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

  test 'graph should include users' do
    users = @org.graph[:users]
    assert_equal [users(:one), users(:three), users(:four)].map(&:id),
      users.map { |u| u[:id] }
  end

  test 'graph should include connections as [[sharer_id, scanner_id]]' do
    connections = @org.graph[:connections]
    c1 = connections(:one)
    c2 = connections(:two)
    assert_equal [[c1.sharer_id, c1.scanner_id], [c2.sharer_id, c2.scanner_id]],
      connections
  end

  test 'next_pseudonym should change when user count changes' do
    pseudonym_0 = @org.next_pseudonym
    pseudonym_1 = @org.next_pseudonym
    assert_equal pseudonym_0, pseudonym_1

    @org.users << users(:two)
    pseudonym_2 = @org.next_pseudonym
    assert_not_equal pseudonym_1, pseudonym_2
  end
end