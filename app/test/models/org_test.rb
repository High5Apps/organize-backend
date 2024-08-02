require "test_helper"

class OrgTest < ActiveSupport::TestCase
  setup do
    @org = orgs(:one)
  end

  test 'should be valid' do
    assert @org.valid?
  end

  test 'encrypted_name should be present' do
    @org.encrypted_name = nil
    assert @org.invalid?
  end

  test 'encrypted_name error messages should not include "Encrypted"' do
    @org.encrypted_name = nil
    @org.valid?
    assert_not @org.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_name should be less than MAX_NAME_LENGTH' do
    @org.encrypted_name.ciphertext = \
      Base64.strict_encode64('a' * Org::MAX_NAME_LENGTH)
    assert @org.valid?
    @org.encrypted_name.ciphertext = \
      Base64.strict_encode64('a' * (1 + Org::MAX_NAME_LENGTH))
    assert @org.invalid?
  end

  test 'encrypted_member_definition should be present' do
    @org.encrypted_member_definition = nil
    assert @org.invalid?
  end

  test 'encrypted_member_definition error messages should not include "Encrypted"' do
    @org.encrypted_member_definition = nil
    @org.valid?
    assert_not @org.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_member_definition should be less than MAX_MEMBER_DEFINITION_LENGTH' do
    @org.encrypted_member_definition.ciphertext = \
      Base64.strict_encode64('a' * Org::MAX_MEMBER_DEFINITION_LENGTH)
    assert @org.valid?
    @org.encrypted_member_definition.ciphertext = \
      Base64.strict_encode64('a' * (1 + Org::MAX_MEMBER_DEFINITION_LENGTH))
    assert @org.invalid?
  end

  test 'graph should include blocked_user_ids' do
    expected_ids = @org.users.blocked.ids
    assert_not_empty expected_ids
    assert_equal expected_ids.sort, @org.graph[:blocked_user_ids].sort
  end

  test 'graph should include left_org_user_ids' do
    expected_ids = @org.users.left_org.ids
    assert_not_empty expected_ids
    assert_equal expected_ids.sort, @org.graph[:left_org_user_ids].sort
  end

  test 'graph should include user_ids' do
    assert_equal @org.users.ids.sort, @org.graph[:user_ids].sort
  end

  test 'graph should include connections as [[sharer_id, scanner_id]]' do
    connections = @org.graph[:connections]
    c1 = connections(:one)
    c2 = connections(:two)
    c3 = connections(:three)
    assert_equal [
      [c1.sharer_id, c1.scanner_id],
      [c2.sharer_id, c2.scanner_id],
      [c3.sharer_id, c3.scanner_id],
    ], connections
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
