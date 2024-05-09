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

  test 'nomination should be present when ballot is an election' do
    assert @election_candidate.ballot.election?
    @election_candidate.nomination = nil
    assert @election_candidate.invalid?
  end

  test 'nomination should be absent when ballot is a non-election' do
    assert_not @candidate.ballot.election?
    @candidate.nomination = nominations :election_one_choice_one
    assert @candidate.invalid?
  end

  test 'nomination nominee should match candidate user' do
    ballot = ballots :election_one
    nomination = nominations :election_one_choice_four
    other_user = users :four
    assert_not_equal nomination.nominee, other_user
    candidate = ballot.candidates.build nomination:, user: other_user
    assert_not candidate.save
  end

  test 'encrypted_title should be absent when ballot is an election' do
    @election_candidate.encrypted_title = @candidate.encrypted_title
    assert @election_candidate.invalid?
  end

  test 'encrypted_title should be present when ballot is a non-election' do
    @candidate.encrypted_title = nil
    assert @candidate.invalid?
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

  test 'user should be absent for non-elections' do
    @candidate.user = users :one
    assert @candidate.invalid?
  end

  test 'user should be present for elections' do
    @election_candidate.user = nil
    assert @election_candidate.invalid?
  end

  test "user should be in Ballot creator's Org for elections" do
    user_in_another_org = users :five
    assert_not_equal  user_in_another_org.org,
      @election_candidate.ballot.user.org
    @election_candidate.user = user_in_another_org
    assert @election_candidate.invalid?
  end
end
