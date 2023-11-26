require "test_helper"

class VoteTest < ActiveSupport::TestCase
  setup do
    @vote = votes(:one)
  end

  test 'should be valid' do
    assert @vote.valid?
  end

  test 'ballot should be present' do
    @vote.ballot = nil
    assert @vote.invalid?
  end

  test 'candidate_ids should be present' do
    @vote.candidate_ids = nil
    assert @vote.invalid?
  end

  test 'candidate_ids can be empty' do
    @vote.candidate_ids = []
    assert @vote.valid?
  end

  test 'candidate_ids should be foreign keys' do
    @vote.candidate_ids = ['a']
    assert @vote.invalid?
  end

  test 'candidate_ids length should be less than MAX_CANDIDATE_IDS_PER_VOTE' do
    ballot_candidate_ids = @vote.ballot.candidates.ids
    assert_operator ballot_candidate_ids.length,
      :>, Vote::MAX_CANDIDATE_IDS_PER_VOTE
    @vote.candidate_ids = ballot_candidate_ids
    assert @vote.invalid?
  end

  test 'candidate_ids should be a subset of ballot.candidates.ids' do
    canididate_from_another_ballot = candidates(:three)
    assert_not_equal @vote.ballot, canididate_from_another_ballot.ballot
    @vote.candidate_ids = [canididate_from_another_ballot.id]
    @vote.save validate: false
    assert @vote.invalid?
  end

  test 'user should be present' do
    @vote.user = nil
    assert @vote.invalid?
  end
end
