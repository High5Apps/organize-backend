require "test_helper"

class OrgTest < ActiveSupport::TestCase
  setup do
    @org = orgs(:one)
    @other_org = orgs(:two)
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

  test 'email should be present' do
    @org.email = nil
    assert @org.invalid?
  end

  test 'email should have the correct format' do
    @org.email = 'abc.com'
    assert @org.invalid?
  end

  test 'email should not be longer than MAX_EMAIL_LENGTH' do
    [
      [Org::MAX_EMAIL_LENGTH, true],
      [1 + Org::MAX_EMAIL_LENGTH, false],
    ].each do |length, valid|
      suffix = '@example.com'
      @org.email = "#{'a' * (length - suffix.length)}#{suffix}"
      assert_equal @org.valid?, valid
    end
  end

  test 'email should be normalized before validation' do
    @org.email = " Email@exampLe.cOm\n"
    assert @org.valid?
    assert_equal @org.email, 'email@example.com'
  end

  test 'email should be unique' do
    @org.email = @other_org.email
    assert @org.invalid?
  end

  test 'verification_code should be present' do
    @org.verification_code = nil
    assert @org.invalid?
  end

  test 'verification_code should be VERIFICATION_CODE_LENGTH' do
    [
      [Org::VERIFICATION_CODE_LENGTH - 1, false],
      [Org::VERIFICATION_CODE_LENGTH, true],
      [Org::VERIFICATION_CODE_LENGTH + 1, false],
    ].each do |length, valid|
      @org.verification_code = '1' * length
      assert_equal @org.valid?, valid
    end
  end

  test 'verification_code should not allow non-digit characters' do
    @org.verification_code = '12345a'
    assert @org.invalid?
  end

  test 'verification_code should be set to NON_PRODUCTION_VERIFICATION_CODE before validation in non-production environments for new Orgs' do
    assert_not Rails.env.production?
    org = Org.new email: random_email
    org.valid?
    assert_equal org.verification_code, Org::NON_PRODUCTION_VERIFICATION_CODE
  end

  test 'verification_code should be set randomly before validation in production environments for new Orgs' do
    Rails.env = 'production'
    assert Rails.env.production?

    org = Org.new email: random_email
    org.valid?
    assert_match(/\A\d{6}\z/, org.verification_code)

    # This is technically possible, but very unlikely
    assert_not_equal org.verification_code,
      Org::NON_PRODUCTION_VERIFICATION_CODE

    Rails.env = 'test'
  end

  test 'verification_code should use demo_mode_code if email exactly matches' do
    demo_mode_codes = { random_email => '123456', random_email => '987654' }
    with_rails_credentials(demo_mode_codes:) do
      demo_mode_codes.each do |email, code|
        org = Org.new(email:)
        org.valid?
        assert_equal org.verification_code, code
      end
    end
  end

  test 'verification_code should use demo_mode_code if normalized email matches' do
    code = '123456'
    email = random_email
    with_rails_credentials(demo_mode_codes: { email => code }) do
      org = Org.new email: " #{email.upcase}\n"
      org.valid?
      assert_equal org.verification_code, code
    end
  end

  test 'verify should return false if the code is incorrect' do
    assert_not @org.verify('BAD_CODE')
  end

  test 'verify should return false if the code is blank' do
    assert_not @org.verify('')
  end

  test 'verify should return true if the code is correct' do
    assert @org.verify(@org.verification_code)
  end

  test 'verify should set verified_at to the current time on success' do
    @org.verified_at = nil
    freeze_time do
      @org.verify(@org.verification_code)
      assert_equal @org.verified_at, Time.now.utc
    end
  end

  test 'verify should not update verified_at if already verified' do
    assert_not_nil @org.verified_at
    assert_no_changes -> { @org.verified_at } do
      @org.verify(@org.verification_code)
    end
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
