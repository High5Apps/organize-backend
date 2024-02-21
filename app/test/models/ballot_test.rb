require "test_helper"

class BallotTest < ActiveSupport::TestCase
  setup do
    @ballot = ballots(:one)
    @ballot_without_votes = ballots(:five)
    @election = ballots(:election_one)
    @multi_choice_ballot = ballots(:multi_choice_one)
  end

  test 'should be valid' do
    assert @ballot.valid?
    assert @ballot_without_votes.valid?
    assert @election.valid?
    assert @multi_choice_ballot.valid?
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
    @multi_choice_ballot.max_candidate_ids_per_vote = nil
    assert @multi_choice_ballot.valid?
  end

  test 'max_candidate_ids_per_vote should default to 1' do
    assert_equal 1, Ballot.new.max_candidate_ids_per_vote
  end

  test 'max_candidate_ids_per_vote should not be less than 1' do
    @multi_choice_ballot.max_candidate_ids_per_vote = 0
    assert @multi_choice_ballot.invalid?
  end

  test 'max_candidate_ids_per_vote should be an integer' do
    @multi_choice_ballot.max_candidate_ids_per_vote = 1.5
    assert @multi_choice_ballot.invalid?
  end

  test 'max_candidate_ids_per_vote must be 1 for yes_no ballots' do
    assert @ballot.yes_no?
    @ballot.max_candidate_ids_per_vote = 2
    assert @ballot.invalid?
  end

  test 'max_candidate_ids_per_vote must be 1 for elections except for stewards' do
    assert @election.election?
    Office::TYPE_SYMBOLS.each do |office|
      @election.office = office
      @election.max_candidate_ids_per_vote = 2
      if office == :steward
        assert @election.valid?
      else
        assert @election.invalid?
      end
    end
  end

  test 'office should be absent for non-elections' do
    @ballot.office = 'president'
    assert @ballot.invalid?
  end

  test 'office should be required for elections' do
    @election.office = nil
    assert @election.invalid?
  end

  test 'nominations_end_at should be absent for non-elections' do
    @ballot.nominations_end_at = Time.now
    assert @ballot.invalid?
  end

  test 'nominations_end_at should be required for elections' do
    @election.nominations_end_at = nil
    assert @election.invalid?
  end

  test 'nominations_end_at should be after created_at for elections' do
    @election.nominations_end_at = @election.created_at
    assert @election.invalid?
    @election.nominations_end_at = @election.created_at + 1.second
    assert @election.valid?
  end

  test 'term_ends_at should be absent for non-elections' do
    @ballot.term_ends_at = Time.now
    assert @ballot.invalid?
  end

  test 'term_ends_at should be required for elections' do
    @election.term_ends_at = nil
    assert @election.invalid?
  end

  test 'term_ends_at should be after voting_ends_at for elections' do
    @election.term_ends_at = @election.voting_ends_at
    assert @election.invalid?
    @election.term_ends_at = @election.voting_ends_at + 1.second
    assert @election.valid?
  end

  test 'user should be present' do
    @ballot.user = nil
    assert @ballot.invalid?
  end

  test 'voting_ends_at should be present' do
    @ballot.voting_ends_at = nil
    assert @ballot.invalid?
  end

  test 'voting_ends_at should be after created_at for non-elections' do
    @ballot.voting_ends_at = @ballot.created_at
    assert @ballot.invalid?
    @ballot.voting_ends_at = @ballot.created_at + 1.second
    assert @ballot.valid?
  end

  test 'voting_ends_at should be after nominations_end_at for elections' do
    @election.voting_ends_at = @election.nominations_end_at
    assert @election.invalid?
    @election.voting_ends_at = @election.nominations_end_at + 1.second
    assert @election.valid?
  end

  test 'should not create unless office is open' do
    org = orgs :two
    assert_equal ['founder'],
      Office.availability_in(org).filter{ |o| !o[:open] }.map{ |o| o[:type] }
    user = org.users.first
    ballot_template = ballots :election_one

    Office::TYPE_STRINGS.each do |office|
      attributes = \
        ballot_template.attributes.merge id: nil, office:, user_id: user.id
      ballot = user.ballots.create! attributes if office != 'founder'
      assert_not user.ballots.build(attributes).save
      ballot&.destroy!
    end
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

  test 'order_by_active should order by earliest voting_ends_at' do
    ballots = Ballot.order_by_active
    assert_not_empty ballots
    sorted_ballots = ballots.sort_by do |b|
      [[b.nominations_end_at, b.voting_ends_at].compact.min, b.id]
    end
    assert_equal sorted_ballots, ballots
  end

  test 'order_by_active should break ties by lowest id' do
    set_all_ballot_timestamps_equal
    ballots = Ballot.order_by_active
    assert_not_empty ballots
    sorted_ballots = ballots.sort_by do |b|
      [[b.nominations_end_at, b.voting_ends_at].compact.min, b.id]
    end
    assert_equal sorted_ballots, ballots
  end

  test 'order_by_inactive should order by latest voting_ends_at' do
    ballots = Ballot.order_by_inactive
    assert_not_empty ballots

    # Reverse is needed because sort is an ascending sort
    assert_equal ballots.sort_by{ |b| [b.voting_ends_at, b.id] }.reverse,
      ballots
  end

  test 'order_by_inactive should break ties by highest id' do
    set_all_ballot_timestamps_equal
    ballots = Ballot.order_by_inactive
    assert_not_empty ballots

    # Reverse is needed because sort is an ascending sort
    assert_equal ballots.sort_by{ |b| [b.voting_ends_at, b.id] }.reverse,
      ballots
  end

  test 'order_by_active should be the opposite of order_by_inactive for non-elections' do
    ballots = Ballot.not_election
    active = ballots.order_by_active.pluck :id
    inactive = ballots.order_by_inactive.pluck :id
    assert_equal active, inactive.reverse
  end

  test 'order_by_active should be the opposite of order_by_inactive for elections once nominations end' do
    ballots = Ballot.election.where(nominations_end_at: ...Time.now)
    active = ballots.order_by_active.pluck :id
    inactive = ballots.order_by_inactive.pluck :id
    assert_equal active, inactive.reverse
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
          { user:, candidate_ids: [vote_order[i]]}
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

  test 'results should include tie-aware downranked rank' do
    users = @multi_choice_ballot.org.users
    candidates = @multi_choice_ballot.candidates
    [{
      expected_ranks: [2, 2, 2],
      vote_info: [],
    }, {
      expected_ranks: [0, 2, 2],
      vote_info: [
        { user: users.first, candidate_ids: [candidates.first.id] },
      ],
    }, {
      expected_ranks: [0, 2, 2],
      vote_info: [
        { user: users.second, candidate_ids: [candidates.second.id] },
      ],
    }, {
      expected_ranks: [1, 1, 2],
      vote_info: [
        { user: users.first, candidate_ids: [candidates.first.id] },
        { user: users.second, candidate_ids: [candidates.second.id] },
      ],
    }, {
      expected_ranks: [1, 1, 2],
      vote_info: [
        { user: users.first, candidate_ids: [candidates.second.id] },
        { user: users.second, candidate_ids: [candidates.first.id] },
      ],
    }, {
      expected_ranks: [2, 2, 2],
      vote_info: [
        { user: users.first, candidate_ids: [candidates.second.id] },
        { user: users.second, candidate_ids: [candidates.first.id] },
        { user: users.third, candidate_ids: [candidates.third.id] },
      ],
    }].each.with_index do |test_info, i|
      expected_ranks = test_info[:expected_ranks]
      vote_info = test_info[:vote_info]

      @multi_choice_ballot.votes.destroy_all
      assert_empty @multi_choice_ballot.reload.votes

      create_votes @multi_choice_ballot, vote_info
      ranks = @multi_choice_ballot.results.map{ |r| r[:rank] }
      assert_equal expected_ranks, ranks
    end
  end

  test 'winner? should only be true iff rank < max_candidate_ids_per_vote' do
    ballots.each do |ballot|
      max_winners = ballot.max_candidate_ids_per_vote
      ballot.results.each do |result|
        is_winner = result[:rank] < max_winners
        assert_equal is_winner, ballot.winner?(result[:candidate_id])
      end
    end
  end

  test 'winner? should be false when candidate_id is nil' do
    assert_equal false, @ballot.winner?(nil)
  end

  test 'winners should only contain winners' do
    ballots.each do |ballot|
      max_winners = ballot.max_candidate_ids_per_vote
      winners = ballot.winners
      ballot.results.each do |result|
        assert_equal ballot.winner?(result[:candidate_id]),
          winners.include?(result)
      end
    end
  end

  private

  def create_ballots_with_voting_ends_at(voting_ends_ats)
    voting_ends_ats.map do |voting_ends_at|
      ballot = @ballot.dup
      ballot.update!(voting_ends_at:)
      ballot
    end
  end

  def create_ballots_with_created_at(created_ats)
    created_ats.map do |created_at|
      ballot = @ballot.dup
      ballot.update!(created_at:)
      ballot
    end
  end

  def create_votes(ballot, votes_info)
    votes_info.each do |vote_info|
      vote_info[:user].votes.create! ballot:,
        candidate_ids: vote_info[:candidate_ids]
    end
  end

  def set_all_ballot_timestamps_equal
    voting_ends_at = Time.now
    Ballot.all.each do |ballot|
      nominations_end_at = nil

      if ballot.nominations_end_at
        nominations_end_at = voting_ends_at - 1.second
      end

      ballot.update! voting_ends_at:, nominations_end_at:
    end
  end
end
