require "test_helper"

class BallotTest < ActiveSupport::TestCase
  setup do
    @ballot = ballots(:one)
    @ballot_without_votes = ballots(:five)
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

  test 'max_candidate_ids_per_vote should be optional' do
    @ballot.max_candidate_ids_per_vote = nil
    assert @ballot.valid?
  end

  test 'max_candidate_ids_per_vote should default to 1' do
    assert_equal 1, Ballot.new.max_candidate_ids_per_vote
  end

  test 'max_candidate_ids_per_vote should not less than 1' do
    @ballot.max_candidate_ids_per_vote = 0
    assert @ballot.invalid?
  end

  test 'max_candidate_ids_per_vote should be an integer' do
    @ballot.max_candidate_ids_per_vote = 1.5
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

  test 'results should be ordered by most votes first' do
    users = @ballot_without_votes.org.users.limit(3)
    candidates = @ballot_without_votes.candidates
    [
      [candidates.first.id, candidates.first.id, candidates.second.id],
      [candidates.second.id, candidates.second.id, candidates.first.id],
    ].each do |distribution|
      expected_winner = distribution.first
      expected_loser = distribution.last

      distribution.permutation.each do |vote_order|
        @ballot_without_votes.votes.destroy_all
        assert_empty @ballot_without_votes.votes

        vote_info = vote_order.map.with_index do |candidate_id, i|
          { user: users[i], candidate_ids: [candidate_id]}
        end

        create_votes @ballot_without_votes, vote_info
        results = @ballot_without_votes.reload.results
        assert_equal 2, results.length

        candidate_ids = results.map { |r| r[:candidate_id] }
        assert_equal expected_winner, candidate_ids.first
        assert_equal expected_loser, candidate_ids.second

        candidate_vote_counts = results.map { |r| r[:vote_count] }
        assert_equal 2, candidate_vote_counts.first
        assert_equal 1, candidate_vote_counts.second
      end
    end
  end

  test 'results should order tied vote counts by descending candidate_id' do
    users = @ballot_without_votes.org.users
    candidates = @ballot_without_votes.candidates
    [users.first, users.second].permutation.each do |user_order|
      [candidates.first.id, candidates.second.id].permutation do |vote_order|
        @ballot_without_votes.votes.destroy_all
        assert_empty @ballot_without_votes.votes

        vote_info = user_order.map.with_index do |user, i|
          { user: user, candidate_ids: [vote_order[i]]}
        end
        create_votes @ballot_without_votes, vote_info

        results = @ballot_without_votes.reload.results
        candidate_vote_counts = results.map { |r| r[:vote_count] }
        assert_equal 1, candidate_vote_counts.uniq.length

        candidate_ids = results.map { |r| r[:candidate_id] }

        # Reverse is needed because sort is an ascending sort
        assert_equal candidate_ids.sort.reverse, candidate_ids
      end
    end
  end

  test "results should only include each voter's most recent vote" do
    users = @ballot_without_votes.org.users
    candidates = @ballot_without_votes.candidates
    [
      [
        { user: users.first, candidate_ids: [candidates.first.id]},
        { user: users.first, candidate_ids: [candidates.second.id]},
      ],[
        { user: users.first, candidate_ids: [candidates.second.id]},
        { user: users.first, candidate_ids: [candidates.first.id]},
      ]
    ].each do |vote_info|
      @ballot_without_votes.votes.destroy_all
      assert_empty @ballot_without_votes.votes

      create_votes @ballot_without_votes, vote_info

      assert_equal 2, @ballot_without_votes.reload.votes.count
      results = @ballot_without_votes.results
      assert_equal 1, results.first[:vote_count]
      assert_equal vote_info.last[:candidate_ids].first,
        results.first[:candidate_id]
      assert_equal 0, results.second[:vote_count]
      assert_equal vote_info.first[:candidate_ids].first,
        results.second[:candidate_id]
    end
  end

  test 'results should include info for all candidates, not just vote receivers' do
    # No votes
    @ballot_without_votes.votes.destroy_all
    assert_empty @ballot_without_votes.votes

    results = @ballot_without_votes.results
    assert_equal @ballot_without_votes.candidates.count, results.length
    results.each do |r|
      assert r[:candidate_id].present?
      assert_equal 0, r[:vote_count]
    end

    # One vote
    candidate_id = @ballot_without_votes.candidates.first.id
    create_votes @ballot_without_votes, [{
      user: @ballot_without_votes.user,
      candidate_ids: [candidate_id]
    }]
    results = @ballot_without_votes.reload.results
    assert_equal 2, results.length
    assert_equal 1, results.first[:vote_count]
    assert_equal candidate_id, results.first[:candidate_id]
    assert_equal 0, results.last[:vote_count]
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

  def create_votes(ballot, votes_info)
    votes_info.each do |vote_info|
      vote_info[:user].votes.create! ballot: ballot,
        candidate_ids: vote_info[:candidate_ids]
    end
  end
end
