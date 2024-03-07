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

  test 'graph should include user_ids' do
    assert_equal @org.users.ids.sort, @org.graph[:user_ids].sort
  end

  test 'graph should include users' do
    users = @org.graph[:users]
    assert_equal [
      users(:one), users(:four), users(:seven), users(:three),
    ].map(&:id), users.map { |id, _| id }

    first_user = users[users(:one).id]
    second_user = users[users(:four).id]
    third_user = users[users(:seven).id]
    fourth_user = users[users(:three).id]

    assert_equal 6, first_user.attributes.count
    assert_not_equal 0, first_user[:joined_at]
    assert_not_empty first_user[:pseudonym]
    assert_not_empty first_user[:id]

    assert_equal 2, first_user[:recruit_count]
    assert_equal 0, second_user[:recruit_count]
    assert_equal 0, third_user[:recruit_count]
    assert_equal 1, fourth_user[:recruit_count]

    assert_equal 2, first_user[:connection_count]
    assert_equal 1, second_user[:connection_count]
    assert_equal 1, third_user[:connection_count]
    assert_equal 2, fourth_user[:connection_count]

    assert_equal ['founder', 'secretary'], first_user.offices
    assert_equal ['president'], second_user.offices
    assert_empty third_user.offices
    assert_empty fourth_user.offices
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
