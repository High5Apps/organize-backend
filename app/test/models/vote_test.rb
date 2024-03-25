require "test_helper"

class VoteTest < ActiveSupport::TestCase
  setup do
    @vote = votes(:one)
    @ballot_without_votes = ballots(:five)
    @election_vote = votes(:election_president_vote)
  end

  test 'should be valid' do
    assert Vote.all.all?(&:valid?)
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

  test 'candidate_ids length should be less than ballot.max_candidate_ids_per_vote' do
    ballot_candidate_ids = @vote.ballot.candidates.ids
    assert_operator ballot_candidate_ids.length,
      :>, @vote.ballot.max_candidate_ids_per_vote
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

  test 'candidate_ids should not contain duplicates' do
    @vote.ballot.max_candidate_ids_per_vote = 2
    @vote.candidate_ids = @vote.candidate_ids * 2
    @vote.save validate: false
    assert @vote.invalid?
  end

  test 'user should be present' do
    @vote.user = nil
    assert @vote.invalid?
  end

  test 'created_at should be before ballot.voting_ends_at' do
    [
      [@vote.ballot.voting_ends_at, false],
      [@vote.ballot.voting_ends_at - 1.second, true],
    ].each do |time, expect_save|
      new_vote = @vote.dup
      @vote.destroy!
      travel_to time do
        assert_equal expect_save, new_vote.save
      end
    end
  end

  test 'created_at should not be before ballot.nominations_end_at' do
    [
      [@election_vote.ballot.nominations_end_at - 1.second, false],
      [@election_vote.ballot.nominations_end_at, true],
    ].each do |time, expect_save|
      new_vote = @election_vote.dup
      @election_vote.destroy!
      travel_to time do
        assert_equal expect_save, new_vote.save
      end
    end
  end

  test 'updated_at should be before ballot.voting_ends_at' do
    [
      [@vote.ballot.voting_ends_at, false],
      [@vote.ballot.voting_ends_at - 1.second, true],
    ].each do |time, expect_save|
      travel_to time do
        @vote.reload.candidate_ids = []
        assert_equal expect_save, @vote.save
      end
    end
  end

  test 'updated_at should not be before ballot.nominations_end_at' do
    [
      [@election_vote.ballot.nominations_end_at - 1.second, false],
      [@election_vote.ballot.nominations_end_at, true],
    ].each do |time, expect_save|
      travel_to time do
        @election_vote.reload.candidate_ids = []
        assert_equal expect_save, @election_vote.save
      end
    end
  end

  test 'should not allow users to double vote the same ballot' do
    assert_no_difference 'Vote.count' do
      assert_raises do
        @election_vote.dup.save
      end
    end
  end
end
