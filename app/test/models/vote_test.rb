require "test_helper"

class VoteTest < ActiveSupport::TestCase
  setup do
    @vote = votes(:one)
    @ballot_without_votes = ballots(:five)
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

  test 'created_at must be before ballot.voting_ends_at' do
    new_vote = @vote.dup
    travel_to @vote.ballot.voting_ends_at - 1.second do
      assert new_vote.save
    end

    new_vote = @vote.dup
    travel_to @vote.ballot.voting_ends_at do
      assert_not new_vote.save
    end
  end

  test 'updated_at must be before ballot.voting_ends_at' do
    original_candidate_ids = @vote.candidate_ids
    travel_to @vote.ballot.voting_ends_at - 1.second do
      @vote.candidate_ids = []
      assert @vote.save
    end

    travel_to @vote.ballot.voting_ends_at do
      @vote.candidate_ids = original_candidate_ids
      assert_not @vote.save
    end
  end

  test 'most_recent should only include a single vote per voter for a given ballot' do
    ballots.each do |ballot|
      voters_count = ballot.votes.joins(:user).group(:user_id).count.length
      vote_count = ballot.votes.count
      assert_operator vote_count, :>=, voters_count

      most_recent_vote_count = ballot.votes.most_recent.count
      assert_equal voters_count, most_recent_vote_count
    end
  end

  test "most_recent should only include each voter's latest vote" do
    assert_equal 0, @ballot_without_votes.votes.count
    assert_equal 0, @ballot_without_votes.votes.most_recent.count

    candidate_id = @ballot_without_votes.candidates.first.id
    3.times do |n|
      created_at = @ballot_without_votes.created_at + n.seconds
      travel_to created_at do
        vote = @ballot_without_votes.votes.create! user: users(:one),
          candidate_ids: [candidate_id]
        assert_equal [vote.id], @ballot_without_votes.votes.most_recent.ids
      end
    end
  end

  test 'most_recent should break tied created_ats by descending vote_id' do
    assert_equal 0, @ballot_without_votes.votes.count

    candidate_id = @ballot_without_votes.candidates.first.id
    created_at = @ballot_without_votes.voting_ends_at - 1.second
    travel_to created_at do
      2.times do
        @ballot_without_votes.votes.create! user: users(:one),
          candidate_ids: [candidate_id]
      end
    end

    assert_equal 1, @ballot_without_votes.votes.pluck(:created_at).uniq.length
    vote_ids = @ballot_without_votes.votes.most_recent.ids

    # Reverse is needed because sort is an ascending sort
    assert_equal vote_ids.sort.reverse, vote_ids
  end
end
