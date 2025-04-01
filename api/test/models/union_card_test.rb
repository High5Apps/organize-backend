require "test_helper"

class UnionCardTest < ActiveSupport::TestCase
  setup do
    @card = union_cards :one
  end

  test 'should be valid' do
    assert @card.valid?
  end

  test 'encrypted_agreement should be present' do
    @card.encrypted_agreement = nil
    assert @card.invalid?
  end

  test 'encrypted_agreement error messages should not include "Encrypted"' do
    @card.encrypted_agreement.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_AGREEMENT_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_agreement should be no longer than MAX_AGREEMENT_LENGTH' do
    @card.encrypted_agreement.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_AGREEMENT_LENGTH)
    assert @card.valid?

    @card.encrypted_agreement.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_AGREEMENT_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_email should be present' do
    @card.encrypted_email = nil
    assert @card.invalid?
  end

  test 'encrypted_email error messages should not include "Encrypted"' do
    @card.encrypted_email.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_EMAIL_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_email should be no longer than MAX_EMAIL_LENGTH' do
    @card.encrypted_email.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_EMAIL_LENGTH)
    assert @card.valid?

    @card.encrypted_email.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_EMAIL_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_employer_name should be present' do
    @card.encrypted_employer_name = nil
    assert @card.invalid?
  end

  test 'encrypted_employer_name error messages should not include "Encrypted"' do
    @card.encrypted_employer_name.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_EMPLOYER_NAME_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_employer_name should be no longer than MAX_EMPLOYER_NAME_LENGTH' do
    @card.encrypted_employer_name.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_EMPLOYER_NAME_LENGTH)
    assert @card.valid?

    @card.encrypted_employer_name.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_EMPLOYER_NAME_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_home_address_line1 should be present' do
    @card.encrypted_home_address_line1 = nil
    assert @card.invalid?
  end

  test 'encrypted_home_address_line1 error messages should not include "Encrypted"' do
    @card.encrypted_home_address_line1.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_HOME_ADDRESS_LINE1_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_home_address_line1 should be no longer than MAX_HOME_ADDRESS_LINE1_LENGTH' do
    @card.encrypted_home_address_line1.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_HOME_ADDRESS_LINE1_LENGTH)
    assert @card.valid?

    @card.encrypted_home_address_line1.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_HOME_ADDRESS_LINE1_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_home_address_line2 should be present' do
    @card.encrypted_home_address_line2 = nil
    assert @card.invalid?
  end

  test 'encrypted_home_address_line2 error messages should not include "Encrypted"' do
    @card.encrypted_home_address_line2.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_HOME_ADDRESS_LINE2_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_home_address_line2 should be no longer than MAX_HOME_ADDRESS_LINE2_LENGTH' do
    @card.encrypted_home_address_line2.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_HOME_ADDRESS_LINE2_LENGTH)
    assert @card.valid?

    @card.encrypted_home_address_line2.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_HOME_ADDRESS_LINE2_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_name should be present' do
    @card.encrypted_name = nil
    assert @card.invalid?
  end

  test 'encrypted_name error messages should not include "Encrypted"' do
    @card.encrypted_name.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_NAME_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_name should be no longer than MAX_NAME_LENGTH' do
    @card.encrypted_name.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_NAME_LENGTH)
    assert @card.valid?

    @card.encrypted_name.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_NAME_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_phone should be present' do
    @card.encrypted_phone = nil
    assert @card.invalid?
  end

  test 'encrypted_phone error messages should not include "Encrypted"' do
    @card.encrypted_phone.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_PHONE_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_phone should be no longer than MAX_PHONE_LENGTH' do
    @card.encrypted_phone.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_PHONE_LENGTH)
    assert @card.valid?

    @card.encrypted_phone.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_PHONE_LENGTH))
    assert @card.invalid?
  end

  test 'signature_bytes should be Base64 encoded' do
    assert_equal @card.signature_bytes,
      Base64.strict_encode64(@card.attributes['signature_bytes'])
  end

  test 'signature_bytes should be present' do
    @card.signature_bytes = nil
    assert @card.invalid?
  end

  test 'signature_bytes should have the correct length' do
    @card.signature_bytes = Base64.decode64('deadbeef')
    assert @card.invalid?
  end

  test 'signed_at should be present' do
    @card.signed_at = nil
    assert @card.invalid?
  end

  test 'user should be present' do
    @card.user = nil
    assert @card.invalid?
  end

  test 'user should not be able to create multiple union cards' do
    assert_no_difference 'UnionCard.count' do
      @card.dup.save
    end
  end

  test 'user uniqueness error message should be custom' do
    duplicate = @card.dup
    assert duplicate.invalid?
    error = duplicate.errors[:user].first
    assert_not_nil error
    assert_not_includes error, 'taken'
  end

  test 'created_at_or_before should not include union_cards created after time' do
    card_created_at = union_cards(:one).created_at
    recent_cards = UnionCard.created_at_or_before(card_created_at)
    assert_not_equal UnionCard.count, recent_cards.count
    assert_not_empty recent_cards
    recent_cards.each do |card|
      assert_operator card.created_at, :<=, card_created_at
    end
  end
end
