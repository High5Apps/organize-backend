require "test_helper"

class CandidateTest < ActiveSupport::TestCase
  setup do
    @candidate = candidates(:one)
  end

  test 'should be valid' do
    assert @candidate.valid?
  end

  test 'ballot should be present' do
    @candidate.ballot = nil
    assert @candidate.invalid?
  end

  test 'encrypted_title should be present' do
    @candidate.encrypted_title = nil
    assert @candidate.invalid?
  end

  test 'encrypted_title should be no longer than MAX_TITLE_LENGTH' do
    @candidate.encrypted_title.ciphertext = \
      Base64.strict_encode64('a' * Candidate::MAX_TITLE_LENGTH)
    assert @candidate.valid?

    @candidate.encrypted_title.ciphertext = \
      Base64.strict_encode64('a' * (1 + Candidate::MAX_TITLE_LENGTH))
    assert @candidate.invalid?
  end
end
