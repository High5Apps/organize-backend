require "test_helper"

class EncryptedMessageTest < ActiveSupport::TestCase
  setup do
    @encrypted_message = posts(:one).encrypted_title
  end

  test 'should be valid' do
    assert @encrypted_message.valid?
  end

  test 'ciphertext should be present' do
    @encrypted_message.ciphertext = nil
    assert @encrypted_message.invalid?
  end

  test 'nonce should be present' do
    @encrypted_message.nonce = nil
    assert @encrypted_message.invalid?
  end

  test 'nonce should have a base64 decoded byte length of BYTE_LENGTH_NONCE' do
    @encrypted_message.nonce = 'abc'
    assert @encrypted_message.invalid?
  end

  test 'auth_tag should be present' do
    @encrypted_message.auth_tag = nil
    assert @encrypted_message.invalid?
  end

  test 'auth_tag should have a base64 decoded byte length of BYTE_LENGTH_AUTH_TAG' do
    @encrypted_message.auth_tag = 'abc'
    assert @encrypted_message.invalid?
  end
end
