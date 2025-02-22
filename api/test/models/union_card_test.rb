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

  test 'signature should return the Base64 encoded version of signature_bytes' do
    assert_equal @card.signature, Base64.strict_encode64(@card.signature_bytes)
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
    assert_not_includes duplicate.errors.full_messages.first, 'taken'
  end
end
