require "test_helper"

class BallotTest < ActiveSupport::TestCase
  setup do
    @ballot = ballots(:one)
  end

  test 'should be valid' do
    assert @ballot.valid?
  end

  test 'category should be present' do
    @ballot.category = nil
    assert @ballot.invalid?
  end

  test 'encrypted_question should be present' do
    @ballot.encrypted_question = nil
    assert @ballot.invalid?
  end

  test 'encrypted_question error messages should not include "Encrypted"' do
    @ballot.encrypted_question = nil
    @ballot.valid?
    assert_not @ballot.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_question should be no longer than MAX_QUESTION_LENGTH' do
    @ballot.encrypted_question.ciphertext = \
      Base64.strict_encode64('a' * Ballot::MAX_QUESTION_LENGTH)
    assert @ballot.valid?

    @ballot.encrypted_question.ciphertext = \
      Base64.strict_encode64('a' * (1 + Ballot::MAX_QUESTION_LENGTH))
    assert @ballot.invalid?
  end

  test 'org should be present' do
    @ballot.org = nil
    assert @ballot.invalid?
  end

  test 'user should be present' do
    @ballot.user = nil
    assert @ballot.invalid?
  end

  test 'voting_ends_at should be present' do
    @ballot.voting_ends_at = nil
    assert @ballot.invalid?
  end

  test 'voting_ends_at should be in the future' do
    @ballot.voting_ends_at = Time.now
    assert @ballot.invalid?
  end

  test 'active_at should include ballots where voting_ends_at is in the future' do
    b1, b2, b3 = create_ballots_with_voting_ends_at(
      [1.second.from_now, 2.seconds.from_now, 3.seconds.from_now])
    query = Ballot.active_at(b2.voting_ends_at)
    assert_not query.exists?(id: [b1, b2])
    assert query.exists?(id: b3)
  end

  test 'created_before should include ballots where created_at is in the past' do
    b1, b2, b3 = create_ballots_with_created_at(
      [1.second.from_now, 2.seconds.from_now, 3.seconds.from_now])
    query = Ballot.created_before(b2.created_at)
    assert query.exists?(id: b1)
    assert_not query.exists?(id: [b2, b3])
  end

  test 'inactive_at should include ballots where voting_ends_at is past or now' do
    b1, b2, b3 = create_ballots_with_voting_ends_at(
      [1.second.from_now, 2.seconds.from_now, 3.seconds.from_now])
    query = Ballot.inactive_at(b2.voting_ends_at)
    assert query.exists?(id: [b1, b2])
    assert_not query.exists?(id: b3)
  end

  private

  def create_ballots_with_voting_ends_at(voting_ends_ats)
    voting_ends_ats.map do |voting_ends_at|
      ballot = @ballot.dup
      ballot.update! voting_ends_at: voting_ends_at
      ballot
    end
  end

  def create_ballots_with_created_at(created_ats)
    created_ats.map do |created_at|
      ballot = @ballot.dup
      ballot.update! created_at: created_at
      ballot
    end
  end
end
