require "test_helper"

class CandidateTest < ActiveSupport::TestCase
  setup do
    @candidate = candidates(:one)
    @election_candidate = candidates(:election_one_choice_one)
  end

  test 'should be valid' do
    assert @candidate.valid?
    assert @election_candidate.valid?
  end

  test 'ballot should be present' do
    @candidate.ballot = nil
    assert @candidate.invalid?
  end

  test 'either encrypted_title or user should be present' do
    @candidate.encrypted_title = nil
    assert @candidate.invalid?

    @candidate.reload.user = users(:one)
    assert @candidate.invalid?

    @election_candidate.user = nil
    assert @election_candidate.invalid?

    @election_candidate.reload.encrypted_title = @candidate.encrypted_title
    assert @election_candidate.invalid?
  end

  test 'encrypted_title error messages should not include "Encrypted"' do
    @candidate.encrypted_title.ciphertext = \
      Base64.strict_encode64('a' * (1 + Candidate::MAX_TITLE_LENGTH))
    @candidate.valid?
    assert_not @candidate.errors.full_messages.first.include? 'Encrypted'
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
