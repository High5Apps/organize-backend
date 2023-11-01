require "test_helper"

class EncryptedMessageTest < ActiveSupport::TestCase
  setup do
    @encrypted_message = posts(:one).encrypted_title
  end

  test 'should be valid' do
    assert @encrypted_message.valid?
  end

  test 'c should be present' do
    @encrypted_message.c = nil
    assert @encrypted_message.invalid?
  end

  test 'n should be present' do
    @encrypted_message.n = nil
    assert @encrypted_message.invalid?
  end

  test 'n should have a base64 decoded byte length of BYTE_LENGTH_NONCE' do
    @encrypted_message.n = 'abc'
    assert @encrypted_message.invalid?
  end

  test 't should be present' do
    @encrypted_message.t = nil
    assert @encrypted_message.invalid?
  end

  test 't should have a base64 decoded byte length of BYTE_LENGTH_AUTH_TAG' do
    @encrypted_message.t = 'abc'
    assert @encrypted_message.invalid?
  end
end
